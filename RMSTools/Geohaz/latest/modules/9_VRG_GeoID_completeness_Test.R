

cat(paste0("  ", "\n"))
cat(paste0("###################################################################################", "\n"))
cat(paste0("=====  ppccvrg_geoid completeness test   ========================", "\n"))
cat(paste0("===================================================================================", "\n"))
cat(paste0("  ", "\n"))


cat("Checking completeness of vrg_geoid table  ----------- \n")

for(ctry in countries) {
  
  cat(paste0( toupper(ctry) , "\n"))
  Test9_query = paste0("SELECT STATECODE, VRGHAZARD FROM ",prl, ctry, "vrg_geoid")
  
  vrg_hazard = data.table(sqlQuery(ghc,as.is=TRUE, Test9_query ))
  
  StCt_byHaz = vrg_hazard[, length(unique(STATECODE)), by = "VRGHAZARD"]
  
  setnames(StCt_byHaz, 'V1', 'UniqStCt')
  
  vrg_table_recordCt = all_tables[ (all_tables[ , .I[grep(paste0("vrg"),TABLE_NAME )]])][Peril == prl & Country == ctry, .(TABLE_NAME, Ct_records )]
  vrg_table_recordCt = vrg_table_recordCt[ !(vrg_table_recordCt[ , .I[grep(paste0("_geoid"),TABLE_NAME )] ])  ]
  
  if(nrow(StCt_byHaz) < nrow(vrg_table_recordCt)){
    cat( cat(paste0("\t Warning! ",  "missing VRGHazard record in ", prl, ctry ,"vrg_geoid table \n")))
  } else {
    
    cat(paste0("\t Pass!", " Corresponding tables of the VRG hazards in the vrg_geoid table all exist", "\n"))
  }
  
  nonFire_recordCt = vrg_table_recordCt[!(vrg_table_recordCt[ , .I[grep("fire",TABLE_NAME) ] ])]
  nonFire_recordCt[,VRGHAZARD := toupper(sub(paste0(prl,ctry, "vrg"),"", TABLE_NAME))]
  nonFire_StCt_byHaz = StCt_byHaz[!StCt_byHaz[ , .I[grep("FIRE",VRGHAZARD) ]]]
  check= merge(nonFire_recordCt, nonFire_StCt_byHaz , by ="VRGHAZARD")
  check = check[order(-Ct_records, -UniqStCt)]
  
  if( nrow(unique(check[, .(Ct_records, UniqStCt)])) > 1 ){
    misHaz = nonFire_StCt_byHaz[UniqStCt == min(UniqStCt)]$VRGHAZARD
    cat( cat(paste0("\t Warning! ",  "missing VRGHazard record in ", prl, ctry ,"vrg_geoid table for ", misHaz,"\n")))
    
  } else {
    
    cat(paste0("\t Pass!", " # of records in the vrg hazard tables are consistent across different vrg-hazards", "\n"))
    
  }
  
  
  ## ToDo Fire records completeness
  
  cat(paste0("\t ----- ------ ------ ------ ------ ------ ------ ", "\n"))  
}