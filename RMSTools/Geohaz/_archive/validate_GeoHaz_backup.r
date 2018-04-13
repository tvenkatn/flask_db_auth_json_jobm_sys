## Tool to validate SoilVs vs. SoilType in Geohazard database
## Currently works for US, can easily be extended to other countries
## Developed by Srinivas Thupakula
## Developed on 6/20/2016
## Added tests by Ching-Yee Chang

cat("\n")
cat("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n")
cat("\014")
cat("\n")
cat("\n")


packs <- c("RODBC", "data.table")
for (i in 1:length(packs)){
  if (!(packs[i] %in% installed.packages())) {
    install.packages(packs[i], repos='http://cran.us.r-project.org')
  }
  library(packs[i], character.only=TRUE)
}




userArgs <- commandArgs(trailingOnly = TRUE)
db <- userArgs[1]
ser <- userArgs[2]
uid <- userArgs[3]
pwd <- userArgs[4]


#suppressWarnings(require(RODBC, quietly = TRUE))
#suppressWarnings(require(data.table, quietly = TRUE))
# require(parallel)https://jira.rms.com/browse/MD-204

t0 = Sys.time()
ghc <- odbcDriverConnect(paste0("driver={SQL Server};
                                          server=",ser,";
                                          database=",db,";
                                          ;uid=",uid,";pwd=",pwd))

cat(paste0("------------------------------------------------------------", "\n"))
##Doc: List all tables
all_tables = data.table(sqlQuery(ghc, as.is = TRUE, "SELECT TABLE_NAME FROM information_schema.tables where TABLE_NAME like '%eq%'"))
cat(paste0("\t", "Test1.1: Total number of tables: ", nrow(all_tables),"\n"))

##Doc: No table should have 0 records
##Doc: 

for(i in 1:nrow(all_tables)){
  all_tables[i , Ct_records := sqlQuery(ghc, as.is = TRUE, paste0("SELECT count(*) from ", all_tables[i,1,with=FALSE ])  )]
}

ZeroRecord_table = all_tables[Ct_records == 0, 1, with = FALSE]

cat(paste0("\t", "Tables of zero records", "\n"))
to_print = c()
for(j in 1:nrow(ZeroRecord_table)){
  to_print = c(to_print,ZeroRecord_table[[1]][j] )
}
cat(paste0("\t", to_print, "\n") )
cat(paste0("=========================================================================", "\n"))


countries = unique(substr(all_tables$TABLE_NAME, 3,4))
cat(paste0("\t Test1.1a: Number of countries: ", length(countries),"\n"))

cat(paste0("\t Test1.1a: List of County Codes: " ,"\n"))
cat(paste0("\t ", countries ))
cat(paste0( "\n"))

cat(paste0("=========================================================================", "\n"))


##Doc: Find each table name for each country
##Doc: List all the unique tables
##Doc: List each country's missing table compared to the all unique tables

table_union = c()
for(i in 1:length(countries)){
  var=paste0(countries[i],"_tables")
  var2 = paste0(countries[i],"_tables_short") 
  var3 = paste0(countries[i],"_tableList")
  assign(var, all_tables[grep(countries[i], all_tables$TABLE_NAME)]$TABLE_NAME)
  assign(var2, sub(paste0("eq",countries[i]), "" ,get(var) ) )
  assign(var3, data.table(get(var2)) )
  setnames(get(var3),'tableList' )
  vv = toupper(paste0(countries[i]))
  get(var3)[, eval(vv) := "Yes" ]
  table_union = union(table_union, get(var2))
}


table_union = data.table(unlist(table_union))
setnames(table_union,  "tableList")

for(i in 1:length(countries)){
  var3 = paste0(countries[i],"_tableList")
  table_union = merge(table_union, get(var3),by = "tableList", all.x = T)
}

to_print = paste0("All unique tables: ")
cat(paste0("\t", to_print , "\n"))
cat(paste0("\t", table_union[[1]], "\n"))

cat(paste0("\t" ,"------------------------------", "\n"))

for(i in 1:length(countries) ){
  idx = which(match(table_union[[i+1]],NA) == 1)
  
  to_print = paste0(  toupper(countries[i]), " missing tables: ")
  for(j in 1:length(idx)){
    to_print = c(to_print,table_union[[1]][idx[j]] )
  }
  cat(paste0("\t", to_print, "\n") )
  cat(paste0("\t" ,"------------------------------", "\n"))
}

cat(paste0("=========================================================================", "\n"))
##=================================================================================
##=================================================================================
##Doc: GEOID consistency test (only for VRG resolution)

table_wGEOID = data.table(sqlQuery(ghc, as.is = TRUE, 
                                   "SELECT COLUMN_NAME, TABLE_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME LIKE '%GEOID%'"))   
  
##Doc: note: eqxxvrg_geoid tables don't contain GEOID column  
##Doc: for every other table, there should be "GEOID" column
all_tables = merge(all_tables, table_wGEOID, by = "TABLE_NAME", all.x = T, all.y=T)

a = unique(all_tables[ !(1:nrow(all_tables) %in% all_tables[ , .I[grep(paste0("vrg_geoid"),TABLE_NAME )]] )]$COLUMN_NAME)

if(length(a) > 1){
  cat(paste0("\t  !!!Error: Some tables (other than eqxxvrg_geoid) don't have GEOID column", "\n" ))
} else {
  cat(paste0("\t  All tables contain GEOID column", "\n" ))
}



##Doc: For each country, # of unique GEOIDs should be the same for all tables that contain GEOID column
tgt_rowIdx = all_tables[,  .I[Ct_records!= 0 & !is.na(COLUMN_NAME)   ] ]

for(i in  tgt_rowIdx ){
  all_tables[i , uniqGEOID_ct := sqlQuery(ghc, as.is = TRUE, paste0("SELECT count(distinct GEOID) from ", all_tables[i,1,with=FALSE ])  )]
}



fire_rowIdx = all_tables[ , .I[  grep(paste0("fire"),TABLE_NAME ) ]] # fire tables contain less records
all_rowIdx = 1:nrow(all_tables)
nofire_rowIdx = all_rowIdx[ !(all_rowIdx %in%  fire_rowIdx) ] 
noFire_tables = all_tables[ nofire_rowIdx  ]

for( ctry in countries){
 a= unique(noFire_tables[noFire_tables[ , .I[grep(paste0(ctry,"vrg"),TABLE_NAME )]]][!is.na(uniqGEOID_ct)]$uniqGEOID_ct)
 
 if(length(a) > 1){
   cat(paste0("\t  for ", toupper(ctry), ", VRG GEOIDs' count numbers NOT consistent among vrg tables", "\n" ))
 } else {
   cat(paste0("\t  for ", toupper(ctry), ", VRG GEOIDs' count numbers ARE consistent among vrg tables", "\n" ))
 }
}



##=================================================================================
##=================================================================================
cat(paste0("=========================================================================", "\n"))

##Doc: eqXXpc tables test 

Vbreaks <- c(3000, 1800, 1100, 760, 560, 413, 270, 180, 120, 80)
RMSindex <- c(0.001, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5)

##cat(paste0("Creating SoilType from Vs30 functions ","\n"))
getSoil <- function(vs) {
  return(approx(Vbreaks, RMSindex,vs, rule = 2)$y)
}

#### PC ####

for( ctr in countries ){

  cat(paste0("Reading PC table for ",  toupper(ctr), " (eq", ctr, "pc) ","\n"))
  tb_name = paste0("eq", ctr, "pc")
  
  #a= grep(tb_name, all_tables$TABLE_NAME)

  if(length(grep(tb_name, all_tables$TABLE_NAME)) == 0 ){
    
    cat(paste0("\t ", toupper(ctr) , " does not have pc table" ,"\n"))
    cat(paste0("\t " ,"---------------------------------  ---------------------------------  ", "\n"))
    
  } else {
    
    uspc <- data.table(sqlQuery(ghc,as.is=TRUE, paste0("select geoid, soil, soilvs, critd, gwd from eq", ctr, "pc")))
    uspc$soil <- as.numeric(as.character(uspc$soil))
    uspc$soilvs <- as.numeric(as.character(uspc$soilvs))
    uspc$gwd <- as.numeric(as.character(uspc$gwd))
    uspc$critd <- as.numeric(as.character(uspc$critd))
    
    ##Doc: Test 1 Soil values tests
    cat(paste0("Calculating soil type ","\n"))
    
    # soil1 <- lapply(uspc$soilvs, getSoil)
    # soil2 <- data.table(data.frame(unlist(soil1), byrow=T))
    # uspc$soilCalc <- soil2[,1,with=F]
    
    uspc[, soilCalc := approx(Vbreaks, RMSindex, soilvs, rule = 2 )$y]
    
    cat(paste0("Comparing with actual soil type ","\n"))
    uspc[,soilDiffPer := 100*(soil-soilCalc)/soilCalc]
    failedUspc <- uspc[soilDiffPer > 0.1 | soilDiffPer < -0.1]
    cat("\n")
    cat(paste0("\t  For " , toupper(ctry), ": Test1: ST vs VS: Total failed records in EQ", toupper(ctr), "PC is ", nrow(failedUspc),"\n"))
    cat(paste0("\t" ,"---------------------------------    ", "\n"))
      

    ##Doc:  Test 2
    if(sum(uspc$gwd)==0 & sum(uspc$critd)==0) {
      cat("\t Test2: CRITD and GWD are 0 in pc table, not comparing them \n")
      } else {
      
      uspcz <- uspc[gwd==0]
      if(!nrow(uspcz[critd==0])==0){
        numEr <- nrow(uspcz[critd==0])
      } else {numEr <- 0}
      uspcnz <- uspc[!gwd==0]
      uspcnz[,gwd_diff := 100*(critd-gwd)/gwd]
      failedCritd <- uspcnz[gwd_diff > 0.1 | gwd_diff < -0.1]
      cat(paste0("\t Test2: CRITD vs GWD: Total failed records in EQ",toupper(ctr),"PC is ", nrow(failedCritd)+numEr,"\n"))
      cat(paste0("\t" ,"---------------------------------  ", "\n"))
    }
    
    ##Doc:  Test 3
    numStates <- data.table(sqlQuery(ghc,as.is=TRUE,"select distinct STATECODE from equspc"))
    if(length(numStates) < 50) {
      cat(paste0("\t Test3: WARNING: Number of states in ",toupper(ctr), " is less than 50 ( ",nrow(numStates),")","\n"))}
    
    cat(paste0("\t" ,"---------------------------------  ---------------------------------  ", "\n"))
    
    
    }

}




# cat(paste0("\t Current work directory is ", getwd(),"\n"))

#### VRG ###

for(ctry in countries){
  
  rm(usvrg, usvrgsoil, usvrgsoilvs)
  gc()
  
  #t0=Sys.time()
  usvrgsoil <- data.table(sqlQuery(ghc,as.is=TRUE,paste0("select geoid, haz as soil from eq", toupper(ctry), "vrgsoil")))
  usvrgsoilvs <- data.table(sqlQuery(ghc,as.is=TRUE,paste0("select geoid, soilvs from eq", toupper(ctry) , "vrgsoilperiod")))
  setkey(usvrgsoil,geoid)
  setkey(usvrgsoilvs,geoid)
  usvrg <- usvrgsoil[usvrgsoilvs]
  usvrg[, soil := as.numeric(soil)]
  usvrg[, soilvs := as.numeric(soilvs)]
  # usvrg$soil <- as.numeric(as.character(usvrg$soil))
  # usvrg$soilvs <- as.numeric(as.character(usvrg$soilvs))
  #print(Sys.time()-t0)
  
  
  
  # # ncl <- detectCores()
  # # cl <- makeCluster(getOption("cl.cores", ncl))
  # # clusterExport(cl=cl, varlist=c("Vbreaks","RMSindex","usvrg"), envir=environment())
  # # soil1 <- parLapply(usvrg$soilvs, getSoil)
  # # stopCluster(cl)
  # 
  # t0=Sys.time()
  # soil1 <- lapply(usvrg$soilvs, getSoil)
  # soil2 <- data.table(data.frame(unlist(soil1), byrow=T))
  # usvrg$soilCalc2 <- soil2[,1,with=F]
  # print(Sys.time()-t0)
  
  
  #t0=Sys.time()
  usvrg[, soilCalc := approx(Vbreaks, RMSindex, soilvs, rule = 2 )$y]
  #print(Sys.time()-t0)
  
  
  usvrg[,soilDiffPer := 100*(soil-soilCalc)/soilCalc]
  failedUsvrg <- usvrg[soilDiffPer > 0.1 | soilDiffPer < -0.1]
  cat("\n")
  cat(paste0("\t Total failed records in EQ ", toupper(ctry), " VRG is ", nrow(failedUsvrg),"\n"))
  
  
  
  
}


##=================================================================================
##=================================================================================
##Doc: PostalCode consistency across VULN DB and GEOHaz DB
## for US first
vdbc <- odbcDriverConnect(paste0("driver={SQL Server};
                                 server=","Cadt0997",";
                                 database=","RMS_VULN_NAEQ_v6a_SL_YrMod_NG_BIiter0",";
                                 ;uid=",uid,";pwd=",pwd))
GH_uspc = data.table(sqlQuery(ghc, as.is = TRUE, "select distinct GEOID as POSTALCODE  from equspc")) 
GH_uspc[, GeoHz := "YES"]


Vul_uspc = data.table(sqlQuery(vdbc, as.is = TRUE, "select distinct POSTALCODE from vgeo 
                               where POSTALCODE is not NULL and country = 'US'")) 
Vul_uspc[, Vul := "YES"]

check = merge(Vul_uspc,GH_uspc, by = "POSTALCODE", all.x = T )
problm_PC = check[Vul == "YES" & is.na(GeoHz)]
Ct_miss_usPC = nrow(problm_PC)
if(Ct_miss_usPC != 0){
  cat(paste0("\t", "There are ", Ct_miss_usPC, " PostalCode missing in GeoHaz DB", "\n" ))
  write.table(problm_PC, file="E:\\NAEQ_GeoHaz\\Missing_PC_inGeoHazDB.csv", row.names = F, col.names = T, sep=",", quote = T)
  
}

print(Sys.time() - t0)

odbcClose(ghc)
odbcClose(vdbc)

cat("\n")
cat("\n")
cat("\014")
cat("\n")