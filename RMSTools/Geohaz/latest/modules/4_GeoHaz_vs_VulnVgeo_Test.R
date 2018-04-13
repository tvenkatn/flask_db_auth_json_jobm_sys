
cat(paste0("  ", "\n"))
cat(paste0("###################################################################################", "\n"))
cat(paste0("=====  Cross check between GeoHazard DB and Vuln.vgeo   ===========================", "\n"))
cat(paste0("===================================================================================", "\n"))
cat(paste0("  ", "\n"))


cat("Checking various GEOIDs consistency across Geohazard and Vuln  ----------- \n")
# cat(paste0("Checking various GEOIDs consistency across Geohazard DB and Vuln vgeo table ----- ", "\n"))


configdir = getwd()
source("modules/RmsJSON.r")
line = readJSON(configdir,"config.json")    
CF<-fromJSON(paste(line, collapse=""))     ## need rjson package


if(CF$Vulnerability$db != ""){
  cat("Connecting to Vulnerability DB provided by config.json  \n")

  
  VulDB <- CF$Vulnerability$db
  VulSer <- CF$Vulnerability$server
  uid <- CF$Vulnerability$userid
  pwd <- CF$Vulnerability$password
  

  
  
} else {
  
  cat("Connecting to default Vulnerability DB \n")
  
  VulDB = "RMS_VULN_NAEQ_v6"
  VulSer= "camodelrdp09"
  uid <- userArgs[3]
  pwd <- userArgs[4]
  
}

vdbc <- odbcDriverConnect(paste0("driver={SQL Server};
                                 server=", VulSer ,
                                 "; database=", VulDB,";
                                 ;uid=",uid,";pwd=",pwd))


if(vdbc == -1){
  cat("\n\n\n")
  cat("ODBC connection to Vulnerability DB failed \n")
  cat("\t Please check Vulnerability DB info in config file  \n")
  cat("Skipping these tests because fail to connect to Vulnerability DB \n")
  cat(paste0("Skipping these tests because fail to connect to Vulnerability DB", "\n"))
  
  cat("\n\n")
  
} else {
  cat(paste0(VulDB, " (", VulSer,  ")  \n"))
  
  eqvgeoQuery = paste0("SELECT TABLE_NAME FROM information_schema.tables where TABLE_NAME  like 'eqvgeo%'")
  eqvgeoTbls =  data.table(sqlQuery(vdbc, as.is = TRUE, eqvgeoQuery )) 
  
  ##=================================================================================
  ##=================================================================================
  ## Function for cross check geoid consistency 
  ## between vgeo(in VulnDB) and corresponding table in GeoHaz
  
  
  CheckGeoHzNVgeo <- function(ctry, GeohzTbl, VgeoColn ){
    
    geohzQuery = paste0("select distinct GEOID as ", VgeoColn ,  " from eq", ctry, GeohzTbl)
    vgeoQuery = paste0("select distinct ", VgeoColn, " from eqvgeo", ctry  ," where ", VgeoColn," is not NULL")
    
    GH_uspc = data.table(sqlQuery(ghc, as.is = TRUE,  geohzQuery )) 
    GH_uspc[, GeoHz := "YES"]
    
    Vul_uspc = data.table(sqlQuery(vdbc, as.is = TRUE, vgeoQuery )) 
    
    if(nrow(Vul_uspc) == 0){
      cat(paste0("\t ", toupper(ctry) , " does not have ", VgeoColn," records in Vuln.eqvgeo", ctry ," table" ,"\n"))
    } else {
      Vul_uspc[, Vul := "YES"]
      
      check = merge(Vul_uspc,GH_uspc, by = VgeoColn, all.x = T )
      problm_PC = check[Vul == "YES" & is.na(GeoHz)]
      Ct_miss_usPC = nrow(problm_PC)
      
      if(Ct_miss_usPC != 0){
        cat(paste0("\t ", Ct_miss_usPC," ",VgeoColn ," missing in GeoHazard eq", toupper(ctry), GeohzTbl," table \n" ))
        write.table(problm_PC, file=paste0("log/", tStamp , toupper(ctry) ,"_Missing_", VgeoColn,"_in_", db, "_",".csv"), row.names = F, col.names = T, sep=",", quote = T)
      } else {
        
        cat(paste0("\t ",'Pass! GEOIDs in GeoHazrd.eq',ctry,GeohzTbl, ' and in Vuln.eqvgeo', ctry ,"'s ", VgeoColn ," are consistent. \n"))
        
      }
    }
    cat(paste0("\t " ,"----- ----- ----- ----- ----- ----- ----- ----- ----- -----", "\n"))
    
  }
  
  
  ## Complete corresponding GeoResolution Code in both DBs
  
  # this is the most inclusive list of the corrsponding lists 
  # However, some counties may have not have all the geo-resolution
  GeoHazResTablesAll = c("st", "dt" ,"cy", "cr", "pc", "ct")
  # VgeoResColnsAll = c("Admin1Code", "Admin2Code" ,"Admin3Code", "Zone1", "POSTALCODE", "CITYCODE")   # for vgeo table
  VgeoResColnsAll = c("STATE", "DSTRCTCODE", "COUNTYNUM", "CRESTA","POSTALCODE", "CITY")   # for eqvgeoxx tables
  
  for(ctry in countries){
    
    cat(paste0( toupper(ctry) , "\n"))
    
    for(iRes in 1:length(GeoHazResTablesAll) ){
      
      GeohzTbl = GeoHazResTablesAll[iRes]
      VgeoColn = VgeoResColnsAll[iRes]
      
      tb_name = paste0("eq", ctry, GeohzTbl )
      
      eqvgeotbl_name = paste0("eqvgeo", ctry)
      
      if(length(  grep(tb_name, all_tables$TABLE_NAME)   ) == 0 ){
        
        cat(paste0("\t ", "GeoHazard does not have eq", toupper(ctry) ,GeohzTbl ," table" ,"\n"))
        cat(paste0("\t " ,"----- ----- ----- ----- ----- ----- ----- ----- ----- -----", "\n"))
        
       } else if ( length(  grep(tb_name, ZeroRecord_table$TABLE_NAME) ) >0  ){ 
        
          cat(paste0("\t ", "Warning!  GeoHazard's eq", toupper(ctry) ,GeohzTbl ," table is empty" ,"\n"))
          cat(paste0("\t " ,"----- ----- ----- ----- ----- ----- ----- ----- ----- -----", "\n"))
          
          
       } else if ( length( grep(eqvgeotbl_name, eqvgeoTbls$TABLE_NAME)   ) == 0 ){
          
          cat(paste0("\t ", "Vuln DB does not have eqvgeo",ctry , " table" ,"\n"))
          cat(paste0("\t " ,"----- ----- ----- ----- ----- ----- ----- ----- ----- -----", "\n"))
          
       } else {  CheckGeoHzNVgeo(ctry, GeohzTbl, VgeoColn )  }
        
      }
      
  }
  
  odbcClose(vdbc)
  
  }
  
  
  




