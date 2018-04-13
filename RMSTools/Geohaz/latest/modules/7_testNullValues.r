## tests if null values exist in any table other than PC fields in Admin tables
## test developed and added on 20160901 (yyyymmdd)

cat(paste0("  ", "\n"))
cat(paste0("Empty tables and the following columns are ommitted from this test:  ", CF$nullAccepted,"\n"))

# For Landslide columns
if(prl == 'eq'){
  
  str_for_qry = paste("TABLE_NAME like '",prl,countries, sep="", collapse = "%' or ")
  str_for_qry = paste(str_for_qry, "%'", sep="")
  qry = paste0("SELECT TABLE_NAME, COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS where ",str_for_qry)

	allTabs <- data.table(sqlQuery(ghc, qry))
	allTabs <- allTabs[!TABLE_NAME %in% ZeroRecord_table$TABLE_NAME]
	allTabs <- allTabs[TABLE_NAME %like% "eq"]
	nullFailCount <- 0
	for(i in 1:nrow(allTabs)){
		#nNull <- sqlQuery(ghc,paste0("select count(*) from ",allTabs[i,]$TABLE_NAME," where ",allTabs[i,]$COLUMN_NAME," IS NULL"))
		nNull <- as.numeric(sqlQuery(ghc,paste0("select count(*) from ",allTabs[i,]$TABLE_NAME," where ",allTabs[i,]$COLUMN_NAME," IS NULL")))
		if((nNull > 0) & (!allTabs[i,]$COLUMN_NAME %like% CF$nullAccepted)) {
			cat(paste0("\t Fail! ",allTabs[i,]$COLUMN_NAME, " in ", allTabs[i,]$TABLE_NAME, " table has ",nNull," records that are NULL \n"))
			nullFailCount <- nullFailCount + 1
		}
	}
	if(nullFailCount == 0) {cat(paste0("Pass! No tables have NULL values (test not performed for omitted tables) \n"))}
}


