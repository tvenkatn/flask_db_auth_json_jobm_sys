
## Consistence Cross Check between GeoHaz and Geography


cat(paste0("  ", "\n"))
cat(paste0("###################################################################################", "\n"))
cat(paste0("=====  Cross check between GeoHazard DB and NGGeography   ========================", "\n"))
cat(paste0("===================================================================================", "\n"))
cat(paste0("  ", "\n"))


cat("Checking various GEOIDs consistency across Geohazard and NGGeography  ----------- \n")
# cat(paste0("Checking various GEOIDs consistency across Geohazard DB and Vuln vgeo table ----- ", "\n"))


configdir = getwd()
source("modules/RmsJSON.r")
line = readJSON(configdir,"config.json")    
CF<-fromJSON(paste(line, collapse=""))     ## need rjson package


if(CF$NGGeography$db != ""){
  cat("Connecting to RMS_NGGeography DB provided by config.json  \n")
  
  GeoDB <- CF$NGGeography$db
  GeoSer <- CF$NGGeography$server
  Geouid <- CF$NGGeography$userid
  Geopwd <- CF$NGGeography$password
  
} else {
  
  cat("Connecting to default RMS_NGGeography DB \n")
  
  GeoDB = "RMS_NGGeography"
  GeoSer= "ca-md1-02"
  uid <- userArgs[3]
  pwd <- userArgs[4]
  
}

geoc <- odbcDriverConnect(paste0("driver={SQL Server};
                                 server=", GeoSer ,
                                 "; database=", GeoDB,";
                                 ;uid=",Geouid,";pwd=",Geopwd))

if(geoc == -1){
  cat("\n\n\n")
  cat("ODBC connection to RMS_NGGeography DB failed \n")
  cat("\t Please check RMS_NGGeography DB info in config file  \n")
  cat("Skipping these tests because fail to connect to RMS_NGGeography DB \n")
  cat(paste0("Skipping these tests because fail to connect to RMS_NGGeography DB", "\n"))
  
  cat("\n\n")
  
} else {
  
  eqvgeoQuery = paste0("SELECT TABLE_NAME FROM information_schema.tables where TABLE_NAME  like 'eqvgeo%'")
 
  
  ##=================================================================================
  ##=================================================================================
  ## Function for cross check geoid consistency 
  ## between vgeo(in VulnDB) and corresponding table in GeoHaz
  
  
  CheckGeoHazVsNGGeo_GDMIDCODE <- function(ctry, GeohzTbl, NGGeoTbl, NGGeoAddrMch ){
    
    geohzQuery = paste0("select distinct GDMID, GEOID from ", prl , ctry, GeohzTbl)
    NGGeoQuery = paste0("select distinct GDMID, CODE as GEOID from ", NGGeoTbl, " where MODELCODE like '", toupper(ctry), "' and ADDRESSMATCH =  ", NGGeoAddrMch)
    
    GH_Res = data.table(sqlQuery(ghc, as.is = TRUE,  geohzQuery )) 
    #GH_Res$GDMID = as.character(GH_Res$GDMID)
    GH_Res[, GDMID := sub("(\\.0)","",GDMID) ]
    ## CYC: ToDo should we keep this line?  (for eqcacr GEOID: extra " " at the end )
    GH_Res[, GEOID := sub("(\\ )","",GEOID) ]
    ###==========================================
    GH_Res[, GeoHazDB := 'GeoHaz']
    NGGeo_Res = data.table(sqlQuery(geoc, as.is = TRUE, NGGeoQuery )) 
    NGGeo_Res[, NGGeoDB := 'NGGeo']
    
    Check = merge(GH_Res, NGGeo_Res, by = c("GDMID", "GEOID"), all.x = T, all.y = T)
    
    if(nrow(Check[is.na(GeoHazDB)] ) != 0  | nrow(Check[is.na(NGGeoDB)] ) != 0 ){
      
      cat(paste0("\t Warning! ", prl,ctry, GeohzTbl ," has Inconsistent records of GDMID/CODE as in NGGeography.", NGGeoTbl ,"\n"))
      
      if( nrow(Check[ is.na(NGGeoDB)]) >0){
        a = Check[ is.na(NGGeoDB), .(GDMID, GEOID)]
        if(nrow(a)<10){
          cat(paste0("\t \t Missing records in NGGeography",  "\n"))
          cat(paste0("\t \t ", "GDMID", "\t"   ,"CODE" ,"\n"))
        } else {
          cat(paste0("\t \t Missing records in NGGeography, Count > 10",  "\n"))
          cat(paste0("\t \t ", "GDMID", "\t"   ,"CODE" ,"\n"))
        }

        if(nrow(a)<10){
          for (i in 1: nrow(a)){
            cat(paste0('\t \t ', a[i]$GDMID,'\t' ,a[i]$GEOID, "\n"  ) )
          }
          rm(a)
        } else {
          for (i in 1:10){
            cat(paste0('\t \t ', a[i]$GDMID,'\t' ,a[i]$GEOID, "\n"  ) )
          }
          rm(a)
        }
        cat(paste0("\t " ,"----- ----- ----- ----- ----- ", "\n"))
      }
      
      if( nrow(Check[ is.na(GeoHazDB)]) >0){
        a = Check[ is.na(GeoHazDB), .(GDMID, GEOID)]
        if(nrow(a)<10){
          cat(paste0("\t \t Missing records in GeoHaz",  "\n"))
          cat(paste0("\t \t ", "GDMID", "\t"   ,"GEOID" ,"\n"))
        } else {
          cat(paste0("\t \t Missing records in GeoHaz, Count > 10",  "\n"))
          cat(paste0("\t \t ", "GDMID", "\t"   ,"GEOID" ,"\n"))
        }
        
        if(nrow(a)<10){
          for (i in 1: nrow(a)){
            cat(paste0('\t \t ', a[i]$GDMID,'\t' ,a[i]$GEOID, "\n"  ) )
          }
          rm(a)
        } else {
          for (i in 1: 10){
            cat(paste0('\t \t ', a[i]$GDMID,'\t' ,a[i]$GEOID, "\n"  ) )
          }
          rm(a)
        }

      }
      
      
    } else {
      cat(paste0("\t Pass! ", prl,ctry, GeohzTbl ," has consistent records of GDMID/CODE as in NGGeography.", NGGeoTbl ,"\n"))
    }
    cat(paste0("\t " ,"----- ----- ----- ----- ----- ----- ----- ----- ----- -----", "\n"))
    
  }
  
  
  ## Check consistent GDMID/CODE in non-VRG tables
  
  # this is the most inclusive list of the corrsponding lists 
  # However, some counties may have not have all the geo-resolution
  #GeoHazResTablesAll = c("st", "dt" ,"cy", "cr", "pc", "ct")
  
  GeoHazResTablesAll = c("st", "cr", "pc", "lc")
  NGGeoTableAll = c("a1geolookup", "z1geolookup", "p0geolookup", "p0geolookup")   # for eqvgeoxx tables
  NGGeoAddrMatchAll = c(10, 11, 5, 5 )
  
  cat(paste0("Check for consistent GDMID/CODE in non-VRG tables \n"))
  
  for(ctry in countries){
    
    
    cat(paste0( toupper(ctry) , "\n"))
    
    for(iRes in 1:length(GeoHazResTablesAll) ){
      
      GeohzTbl = GeoHazResTablesAll[iRes]
      NGGeoTbl = NGGeoTableAll[iRes]
      NGGeoAddrMch = NGGeoAddrMatchAll[iRes]
      
      tb_name = paste0("eq", ctry, GeohzTbl )

      
      if(length(  grep(tb_name, all_tables$TABLE_NAME)   ) == 0 ){
        
        #cat(paste0("\t ", "GeoHazard does not have eq", toupper(ctry) ,GeohzTbl ," table" ,"\n"))
        #cat(paste0("\t " ,"----- ----- ----- ----- ----- ----- ----- ----- ----- -----", "\n"))
        
      } else if ( length(  grep(tb_name, ZeroRecord_table$TABLE_NAME) ) >0  ){ 
        
        cat(paste0("\t ", "Warning!  GeoHazard's eq", toupper(ctry) ,GeohzTbl ," table is empty" ,"\n"))
        cat(paste0("\t " ,"----- ----- ----- ----- ----- ----- ----- ----- ----- -----", "\n"))
        
        
      }  else {  CheckGeoHazVsNGGeo_GDMIDCODE(ctry, GeohzTbl, NGGeoTbl, NGGeoAddrMch )  }
      
    }
    
  }
  
#### ===================================================================================
  
  cat(paste0("\t " ,"=================================================================", "\n"))

  cat(paste0("Check for consistence of StateCode in non-VRG tables \n"))
  
  
  all_nonVRGtables = all_tables[ !(all_tables[ , .I[grep(paste0("vrg"),TABLE_NAME )]])][ Peril == prl & Model == mdl ]  # non-VRG tables  
  all_nonVRGtables = all_nonVRGtables[!all_nonVRGtables[ , .I[grep(paste0("cr"),TABLE_NAME )] ]]   ## Cresta tables don't have StateCode
  
  for(ctry in countries){
    
    cat(paste0( toupper(ctry) , "\n"))
    
    NGGeoQuery = paste0("select distinct CODE as StCode from a1geolookup where MODELCODE like '",  toupper(ctry), "'")
    
    StCode = data.table(sqlQuery(geoc, as.is = TRUE,  NGGeoQuery ))
    StCode[, NGGeo := 'NGGeo']
    
    sub_nonVRGTbl = all_nonVRGtables[ Country == ctry]
    nTbl = nrow(sub_nonVRGTbl)
    
    for(i in 1:nTbl){
      
      geohzQuery = paste0("select distinct STATECODE as ",  "StCode"," from ", sub_nonVRGTbl[i]$TABLE_NAME )
      
      GH_Res = data.table(sqlQuery(ghc, as.is = TRUE,  geohzQuery ))
      Tbl_Name = sub_nonVRGTbl[i]$TABLE_NAME
      GH_Res[, eval(Tbl_Name) := Tbl_Name  ]
    
      StCode = merge(StCode, GH_Res, by = "StCode", all.x = T, all.y = T  ) 
    }
    
    c1=names(StCode[,3, with = FALSE])
    GeoHaz_NA = c()
    GeoHaz_NA = c(GeoHaz_NA,nrow(StCode[is.na(get(c1))]) ) 
    if( nrow(StCode[is.na(NGGeo)]) >0 | nrow(StCode[is.na(get(c1))])>0 ){
      cat(paste0("\t Warning! Inconsistent StateCode btw GeoHaz & NGGeography \n"))
      
      if(nrow(StCode[is.na(NGGeo)]) >0){
        a= StCode[is.na(NGGeo)]
        if(nrow(a)<10){
          cat(paste0("\t \t Missing StateCode in NGGeography",  "\n"))
          cat(paste0("\t \t ", "StateCode" ,"\n"))
        } else {
          cat(paste0("\t \t Missing StateCode in NGGeography, Count > 10",  "\n"))
          cat(paste0("\t \t ", "StateCode" ,"\n"))
        }
        
        if(nrow(a)<10){
          for (i in 1: nrow(a)){
            cat(paste0('\t \t ', a[i]$StCode, "\n"  ) )
          }
          rm(a)
        } else {
          for (i in 1: 10){
            cat(paste0('\t \t ', a[i]$StCode, "\n"  ) )
          }
          rm(a)
        }
        
        if(nrow(StCode[is.na(get(c1))]) >0){
          a= StCode[is.na(get(c1))]
          if(nrow(a)<10){
            cat(paste0("\t \t Missing StateCode in GeoHaz",  "\n"))
            cat(paste0("\t \t ", "StateCode" ,"\n"))
          } else {
            cat(paste0("\t \t Missing StateCode in GeoHaz, Count > 10",  "\n"))
            cat(paste0("\t \t ", "StateCode" ,"\n"))
          }
          
          if(nrow(a)<10){
            for (i in 1: nrow(a)){
              cat(paste0('\t \t ', a[i]$StCode, "\n"  ) )
            }
            rm(a)
          } else {
            for (i in 1: 10){
              cat(paste0('\t \t ', a[i]$StCode, "\n"  ) )
            }
            rm(a)
          }
        
        
        
        

      }
      
    }
    
      if(nTbl> 1){
      for (i in 2:nTbl){
        c2=names(StCode[,(i+1), with = FALSE])
        GeoHaz_NA= c(GeoHaz_NA,nrow(StCode[is.na(get(c2))]))
      }
      
      if(length(unique(GeoHaz_NA)) > 1){
        cat(paste0("\t Warning! Inconsistent StateCode in GeoHaz nonVRG tables",  "\n"))
      }
    }
    
    }
    
    cat(paste0("\t " ,"----- ----- ----- ----- ----- ----- ----- ----- ----- -----", "\n"))
  }
  
  
  
  odbcClose(geoc)

  
}






