



cat(paste0("  ", "\n"))

cat(paste0("  ", "\n"))
cat(paste0("###################################################################################", "\n"))
cat(paste0("=====  Tests for Over view    =====================================================", "\n"))
cat(paste0("===================================================================================", "\n"))
cat(paste0("  ", "\n"))

## Get expected countries
expcted_ctrys=c()
if(file.exists("data/GeoHaz_ExpectedTables.csv")){
  expTbls = fread("data/GeoHaz_ExpectedTables.csv")
  expTbls= expTbls[Model == mdl]
  expcted_ctrys = unique(expTbls$Country)
}

## List all tables
if(length(expcted_ctrys) >0){
  str_for_qry = paste("TABLE_NAME like '",prl,expcted_ctrys, sep="", collapse = "%' or ")
  str_for_qry = paste(str_for_qry, "%'", sep="")
  
  all_tables = data.table(sqlQuery(ghc, as.is = TRUE, 
                                   paste0( "SELECT TABLE_NAME FROM information_schema.tables where  ",str_for_qry)))
} else {
  str_for_qry = paste0("'",prl,"%' ")
  all_tables = data.table(sqlQuery(ghc, as.is = TRUE, 
                                   paste0( "SELECT TABLE_NAME FROM information_schema.tables where TABLE_NAME like ",str_for_qry)))
}


all_tables[, GeoHaz := TRUE]
cat(paste0("\t", "Total number of ", prl,"xx tables: ", nrow(all_tables),"\n"))

qry = paste0("SELECT TABLE_NAME FROM information_schema.tables where TABLE_NAME not in 
(SELECT TABLE_NAME FROM information_schema.tables where 
(TABLE_NAME like 'eq%' or TABLE_NAME like 'hu%' or TABLE_NAME like 'fl%' or 
TABLE_NAME  like 'fr%' or TABLE_NAME like 'DB%' or TABLE_NAME like 'rmsver'))
")

probm_tables = data.table(sqlQuery(ghc, as.is = TRUE, qry ))

if(nrow(probm_tables) > 0){
  cat(paste0("\t" ,"Extra tables: " ,"\n")) 
  cat(paste0("\t   " , probm_tables$TABLE_NAME ,"\n")) }

cat(paste0("=========================================================================", "\n"))


## Check if every table is indexed  ##################################################################################
str_for_qry = paste("NAME like '",prl,expcted_ctrys, sep="", collapse = "%' or ")
str_for_qry = paste(str_for_qry, "%'", sep="")

#qry =  paste0("SELECT name FROM sys.tables WHERE OBJECTPROPERTY(object_id,'IsIndexed') = 0 and ", str_for_qry )
qry =  paste0("SELECT name FROM sys.tables WHERE OBJECTPROPERTY(object_id,'IsIndexed') = 0  ")
nonIndexed_tables = data.table(sqlQuery(ghc, as.is = TRUE,qry ))
nonIndexed_tables[, notIndex := "NotIndex"]

nonIndexed_tables = merge(nonIndexed_tables, all_tables, by.x = "name", by.y="TABLE_NAME")

if(nrow(nonIndexed_tables) > 0){
  cat(paste0("\t Fail! ", "Tables not indexed: ",nonIndexed_tables[,1,with=FALSE] , "\n"))
  
} else {
  cat(paste0("\t", "All tables are indexed ", "\n"))
}
cat(paste0("=========================================================================", "\n"))


## list number of countries
countries = unique(substr(all_tables$TABLE_NAME, 3,4))
#cat("Identifying countries \n")
cat(paste0("\t", "Number of countries: ", length(countries),"\n"))

cat(paste0("\t",  "List of Country Codes: " ,"\n"))
cat(paste0("\t   ", data.table(countries)$countries, "\n" ))
cat(paste0("=========================================================================", "\n"))



## No table should have 0 records

for(i in 1:nrow(all_tables)){
  all_tables[i , Ct_records := sqlQuery(ghc, as.is = TRUE, paste0("SELECT count(*) from ", all_tables[i,1,with=FALSE ])  )]
}
ZeroRecord_table = all_tables[Ct_records == 0, 1, with = FALSE]

if(nrow(ZeroRecord_table) >0 ){
  cat(paste0("\t Fail! ", "Empty tables:", "\n"))
  cat(paste0("\t   ", ZeroRecord_table$TABLE_NAME, "\n") )
} else {
  cat(paste0("\t Pass! ", "No Empty tables:", "\n"))
}

cat(paste0("=========================================================================", "\n"))



expected_tables = fread("data/GeoHaz_ExpectedTables.csv")

all_tables = merge(all_tables ,  expected_tables[ Peril == prl & Model == mdl,   ], by.x= 'TABLE_NAME', by.y = 'Table', all.x = T, all.y = T )


for(ctry in countries){
  if(nrow(all_tables[Country == ctry & is.na(GeoHaz)]) > 0) {
    cat(paste0("\t Fail! ", ctry , " Missing tables:", "\n"))
    cat(paste0("\t   ", all_tables[Country == ctry & is.na(GeoHaz)]$TABLE_NAME, "\n") )
    cat(paste0("----- ----- ----- ----- ----- ----- ----- ----- ----- -----", "\n"))
  } else {
    cat(paste0("\t Pass! ", ctry , " No missing tables:", "\n"))
    cat(paste0("----- ----- ----- ----- ----- ----- ----- ----- ----- -----", "\n"))
  }
}
  
cat(paste0("=========================================================================", "\n"))


if(nrow(all_tables[is.na(Model)]) >0){
  cat(paste0("\t Fail! ", "Extra tables:", "\n"))
  cat(paste0("\t   ", all_tables[is.na(Model)]$TABLE_NAME, "\n") )
  cat(paste0("=========================================================================", "\n"))
} else {
  cat(paste0("\t Pass! ", "No Extra ",  prl," tables for ", mdl , "\n"))
  cat(paste0("=========================================================================", "\n"))
}





