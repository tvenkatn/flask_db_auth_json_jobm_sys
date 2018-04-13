
cat(paste0("  ", "\n"))
cat(paste0("###################################################################################", "\n"))
cat(paste0("=====  Tests for non-VRG tables   =================================================", "\n"))
cat(paste0("===================================================================================", "\n"))
cat(paste0("  ", "\n"))
# cat("Tests for non-VRG tables\n")


## data needed for checking soil value conversion
Vbreaks <- c(3000, 1800, 1100, 760, 560, 413, 270, 180, 120, 80)
RMSindex <- c(0.001, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5)


#### For EQ only
#### 2.11.	For non-VRG tables, compare the values in soil column with the interpolated values from soilvs column.  
#### PC ####
#cat(paste0("Checking non-VRG tables ------------------", "\n"))


for( ctry in countries ){
  
  avlb_geoRes = all_tables[ !(all_tables[ , .I[grep(paste0("vrg"),TABLE_NAME )]])][ Peril == prl & Model == mdl & Country == ctry & !is.na(GeoHaz)]$TABLE_NAME
  
  cat(paste0( toupper(ctry) , "\n"))
  
  for(tb_name in avlb_geoRes) {
    
    cat(paste0( tb_name  , "\n"))
    
    if(length(grep(tb_name, all_tables$TABLE_NAME)) == 0 ){
      
      cat(paste0("\t ", toupper(ctry) , " does not have ",tb_name  ," table" ,"\n"))
      cat(paste0("\t " ,"----- ----- ----- ----- ----- ----- ----- ----- ----- -----", "\n"))
      
    } else if ( all_tables[TABLE_NAME == tb_name ]$Ct_records ==0  ){
      
      cat(paste0("\t ", toupper(ctry) , " " ,tb_name  ," table is empty." ,"\n"))
      cat(paste0("\t " ,"----- ----- ----- ----- ----- ----- ----- ----- ----- -----", "\n"))
    }
    else {
      uspc <- data.table(sqlQuery(ghc,as.is=TRUE, paste0("select geoid, soil, soilvs, critd, gwd from ", tb_name)))
      
      if(nrow(uspc[is.na(soil)]) >0 | nrow(uspc[is.na(soilvs)]) >0 |nrow(uspc[is.na(critd)]) >0 | nrow(uspc[is.na(gwd)]) >0 )  {
        
        cat(paste0("\t Fail!! NA occur in soil, soilvs, critd, or gwd columns in ",tb_name ,"\n")) 
        
      }
      
      uspc = uspc[!is.na(soil) & !is.na(soilvs) & !is.na(critd) & !is.na(gwd)]
      
      uspc$soil <- as.numeric(as.character(uspc$soil))
      uspc$soilvs <- as.numeric(as.character(uspc$soilvs))
      uspc$gwd <- as.numeric(as.character(uspc$gwd))
      uspc$critd <- as.numeric(as.character(uspc$critd))
      
      ##Doc: Test 1 Soil values tests
      #cat(paste0("Calculating soil type ","\n"))
      uspc[, soilCalc := approx(Vbreaks, RMSindex, soilvs, rule = 2 )$y]
      
      if(mdl == "NAEQ") {   ## This test is for HD methodology only 
        uspc[,soilDiffPer := 100*(soil-soilCalc)/soilCalc]
        failedUspc <- uspc[soilDiffPer > 0.1 | soilDiffPer < -0.1]
        cat("\n")
        
        if(nrow(failedUspc) > 0){
          cat(paste0("\t Fail!! soil & soilvs values in ", tb_name ," NOT in sync. # of failed records: ", nrow(failedUspc),"\n"))
        } else {
          cat(paste0("\t Pass!! soil & soilvs values in ", tb_name , " are in sync.  \n"))
        }
        cat(paste0("\t " ,"----- ----- ----- ----- ----- ----- ----- ----- ----- -----", "\n"))
        
      }

      
      
      ### 2.12.	Range of values in column soil should be:   0 <=   soil  <= 4.5
      maxSoil = max(uspc$soil)
      minSoil = min(uspc$soil)
      if(maxSoil > 4.5 | minSoil < 0){
        cat(paste0("\t " ,"Fail!! soil values beyond the correct range ", "\n"))
      } else {
        cat(paste0("\t " ,"Pass!! soil values in the correct range ", "\n"))
      }
      cat(paste0("\t " ,"----- ----- ----- ----- ----- ----- ----- ----- ----- -----", "\n"))
      
      
      ### 2.13.	Range of values in column soilvs should be:  0 <=   soilvs  <=  3000
      maxSoilvs = max(uspc$soilvs)
      minSoilvs = min(uspc$soilvs)
      if(maxSoilvs > 3000 | minSoilvs < 0){
        cat(paste0("\t " ,"Fail!! soilvs values beyond the correct range ", "\n"))
      } else {
        cat(paste0("\t " ,"Pass!! soilvs values in the correct range ", "\n"))
      }
      cat(paste0("\t " ,"----- ----- ----- ----- ----- ----- ----- ----- ----- -----", "\n"))
      
      
      
      ##Doc:  Test 2
      if(sum(uspc$gwd)==0 & sum(uspc$critd)==0) {
        cat("\t CRITD and GWD are 0 in ", tb_name ,"table, not comparing them \n")
      } else {
        
        uspcz <- uspc[gwd==0]
        if(!nrow(uspcz[critd==0])==0){
          numEr <- nrow(uspcz[ (critd== 0 & gwd !=0) | (critd != 0 & gwd ==0)])
          # numEr <- nrow(uspcz[critd==0])
        } else {numEr <- 0}
        uspcnz <- uspc[!gwd==0]
        uspcnz[,gwd_diff := 100*(critd-gwd)/gwd]
        failedCritd <- uspcnz[gwd_diff > 0.1 | gwd_diff < -0.1]
        if(nrow(failedCritd)+numEr  >0 ){
          cat(paste0("\t Fail!! CRITD vs GWD: Total failed records in ", tb_name," is ", nrow(failedCritd)+numEr,"\n"))
        } else {
          cat(paste0("\t Pass!! CRITD vs GWD: in sync \n"))
        }
        
        cat(paste0("\t" ,"----- ----- ----- ----- ----- ----- ----- ----- ----- -----", "\n"))
      }

      
      ##Doc:  Test 3
#       numStates <- data.table(sqlQuery(ghc,as.is=TRUE,  paste0("select distinct STATECODE from ", tb_name)  ))
#       if(length(numStates) < 50) {
#         cat(paste0("\t Test3: WARNING: Number of states in ",toupper(ctry), " is less than 50 ( ",nrow(numStates),")","\n"))}
#       
#       cat(paste0("\t " ,"----- ----- ----- ----- ----- ----- ----- ----- ----- -----", "\n"))
      
    }
    
    
    
  }
  
  cat(paste0("=========================================================================", "\n"))
  
}

cat(paste0("=========================================================================", "\n"))






