
## Expected Column Test



expectedColn = fread("data/GeoHaz_ExpectedColumns.csv")



str_for_qry = paste("TABLE_NAME like '",prl,countries, sep="", collapse = "%' or ")
str_for_qry = paste(str_for_qry, "%'", sep="")

# all_tables = data.table(sqlQuery(ghc, as.is = TRUE, 
#                                  paste0( "SELECT TABLE_NAME FROM information_schema.tables where  ",str_for_qry)))

qry = paste0("SELECT TABLE_NAME, COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS where ",str_for_qry)

allTbl_allCol = data.table(sqlQuery(ghc, as.is = TRUE, qry ))
allTbl_allCol[, GeoHaz := "GeoHaz"]


allTbl_allCol_merge = merge(allTbl_allCol, expectedColn[ Model == mdl ], all.x = T, all.y=T, 
                      by.x = c('TABLE_NAME','COLUMN_NAME'), by.y = c('Table', 'Column') )

if( nrow(allTbl_allCol_merge[is.na(GeoHaz)]) >0 ){
  dt = allTbl_allCol_merge[is.na(GeoHaz), .(TABLE_NAME, COLUMN_NAME)]
  cat(paste0("\t Fail! Missing columns in GeoHaz: " ,"\n"))
  cat(paste0("\t \t", "TABLE", "\t"   ,"COLUMN" ,"\n"))
  for (i in 1: nrow(dt)){
    cat(paste0('\t \t', dt[i]$TABLE_NAME,'\t' ,dt[i]$COLUMN_NAME, "\n"  ) )
  }
  rm(dt)
} 

if( nrow(allTbl_allCol_merge[is.na(Model)]) > 0 ) {
  dt = allTbl_allCol_merge[is.na(Model), .(TABLE_NAME, COLUMN_NAME)]
  cat(paste0("\t Fail! Extra columns in GeoHaz: " ,"\n"))
  cat(paste0("\t \t", "TABLE", "\t"   ,"COLUMN" ,"\n"))
  for (i in 1: nrow(dt)){
    cat(paste0('\t \t', dt[i]$TABLE_NAME,'\t' ,dt[i]$COLUMN_NAME, "\n"  ) )
  }
  rm(dt)
}

if((nrow(allTbl_allCol_merge[is.na(Model)])==0)&(nrow(allTbl_allCol_merge[is.na(GeoHaz)])==0)){
  cat(paste0("\t Pass! No Missing or Extra column in GeoHaz: " ,"\n"))
  
}

