

cat(paste0("  ", "\n"))
cat(paste0("###################################################################################", "\n"))
cat(paste0("#####  Tests for VRG tables   #####################################################", "\n"))
cat(paste0("===================================================================================", "\n"))
cat(paste0("  ", "\n"))

cat(paste0("=========================================================================", "\n"))
##=================================================================================
##=================================================================================
## GEOID consistency test (only for VRG resolution) 
## 2.6.	For each country, check that all vrg tables have the same number of unique GEOIDs (except vrgfire) 
cat("Testing GEOID consistency among VRG tables\n")

if(length(expcted_ctrys) >0){
  str_for_qry = paste("TABLE_NAME like '",prl,expcted_ctrys, sep="", collapse = "%' or ")
  str_for_qry = paste(str_for_qry, "%'", sep="")
  
  table_wGEOID = data.table(sqlQuery(ghc, as.is = TRUE, 
                                   paste0("SELECT COLUMN_NAME, TABLE_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME LIKE '%GEOID%' and  (",str_for_qry, ")")))
} else {
  table_wGEOID = data.table(sqlQuery(ghc, as.is = TRUE, 
                                     paste0("SELECT COLUMN_NAME, TABLE_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME LIKE '%GEOID%' 
                                            AND TABLE_NAME like '",  toupper(prl) , "%'")))   
}



## note: eqxxvrg_geoid tables don't contain GEOID column  
## for every other table, there should be "GEOID" column
all_tables = merge(all_tables, table_wGEOID, by = "TABLE_NAME", all.x = T, all.y=T)

a = unique(all_tables[ !(1:nrow(all_tables) %in% all_tables[ , .I[grep(paste0("vrg_geoid"),TABLE_NAME )]] )]$COLUMN_NAME)

if(length(a) > 1){
  cat(paste0("\t  !!!Error: Some VRG tables (other than ", prl, "xxvrg_geoid) don't have GEOID column", "\n" ))
} else {
  cat(paste0("\t  All VRG tables contain GEOID column", "\n" ))
}


## For each country, # of unique GEOIDs should be the same for all tables that contain GEOID column
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
    cat(paste0("\t  Fail!  For ", toupper(ctry), ", VRG GEOIDs' count # NOT consistent among vrg tables", "\n" ))
  } else {
    cat(paste0("\t  Pass!  For ", toupper(ctry), ", VRG GEOIDs' count # are consistent among vrg tables", "\n" ))
  }
}



  
  ##=================================================================================
  ##=================================================================================
  cat(paste0("=========================================================================", "\n"))
  cat("Testing SoilType, VS30 in VRG tables \n")
  ## eqXXpc tables test 
  
  Vbreaks <- c(3000, 1800, 1100, 760, 560, 413, 270, 180, 120, 80)
  RMSindex <- c(0.001, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5)
  
  ##cat(paste0("Creating SoilType from Vs30 functions ","\n"))
  getSoil <- function(vs) {
    return(approx(Vbreaks, RMSindex,vs, rule = 2)$y)
  }
  
  
  
  # cat(paste0("\t Current work directory is ", getwd(),"\n"))
  
  #### VRG ###
  cat(paste0("Checking VRG soil tables ------------------", "\n"))
  cat(paste0("Check VRG tables: Compare haz in vrgsoil with soilvs in vrgsoilperiod", "\n"))
  i=0
  for(ctry in countries){
    
    ta=Sys.time()
    i=i+1
    cat(paste0( toupper(ctry), " (", prl  , ctry, "vrg***) ","\n"))
    # cat(paste0("Comparing for ",  toupper(ctry), " (", prl  , ctry, "vrg***) ","\n")  )
    
    if(i>1) {rm(usvrg, usvrgsoil, usvrgsoilvs);gc()}
    
    #t0=Sys.time()
    usvrgsoil <- data.table(sqlQuery(ghc,as.is=TRUE,paste0("select geoid, haz as soil from ", prl , toupper(ctry), "vrgsoil")))
    setkey(usvrgsoil,geoid)
    
    if(mdl == "NAEQ"){
      
    usvrgsoilvs <- data.table(sqlQuery(ghc,as.is=TRUE,paste0("select geoid, soilvs from ", prl , toupper(ctry) , "vrgsoilperiod")))
    setkey(usvrgsoilvs,geoid)
    usvrg <- usvrgsoil[usvrgsoilvs]
    usvrg[, soil := as.numeric(soil)]
    usvrg[, soilvs := as.numeric(soilvs)]
    

      usvrg[, soilCalc := approx(Vbreaks, RMSindex, soilvs, rule = 2 )$y]
      usvrg[,soilDiffPer := 100*(soil-soilCalc)/soilCalc]
      failedUsvrg <- usvrg[soilDiffPer > 0.1 | soilDiffPer < -0.1]
      cat("\n")
      if(nrow(failedUsvrg) > 0){
        cat(paste0("\t Fail!! vrgsoil.haz & vrgsoilperiod.soilvs NOT in sync. # of failed records: ", nrow(failedUsvrg),"\n"))
      } else {
        cat(paste0("\t Pass!! vrgsoil.haz & vrgsoilperiod.soilvs are in sync \n"))
      }
      cat(paste0("\t " ,"----- ----- ----- ----- ----- ----- ----- ----- ----- -----", "\n"))
      
    }
    
    
    ### 2.8.	In vrgsoil table, range of values in column haz should be:  0 <= haz<= 4.5
    
    maxSoil = usvrgsoil[, max(soil)]
    minSoil = usvrgsoil[, min(soil)]
    
    if(maxSoil > 4.5 | minSoil < 0){
      cat(paste0("\t " ,"Fail!! vrgsoil.haz beyond the correct range ", "\n"))
    } else {
      cat(paste0("\t " ,"Pass!! vrgsoil.haz in the correct range ", "\n"))
    }
    cat(paste0("\t " ,"----- ----- ----- ----- ----- ----- ----- ----- ----- -----", "\n"))
    
    
    ### 2.9.	In vrgsoilvs table, range of values in column soilvs should be:  0 <=   soilvs  <=  3000
    
    if(mdl == "NAEQ"){
      maxSoilvs = usvrg[, max(soilvs)]
      minSoilvs = usvrg[, min(soilvs)]
      
      if(maxSoilvs > 3000 | minSoilvs < 0){
        cat(paste0("\t " ,"Fail!! vrgsoilvs.soilvs beyond the correct range ", "\n"))
      } else {
        cat(paste0("\t " ,"Pass!! vrgsoilvs.soilvs in the correct range ", "\n"))
      }
      cat(paste0("\t " ,"----- ----- ----- ----- ----- ----- ----- ----- ----- -----", "\n"))
      
    }

    
    
  
    
  }
  
  
  






