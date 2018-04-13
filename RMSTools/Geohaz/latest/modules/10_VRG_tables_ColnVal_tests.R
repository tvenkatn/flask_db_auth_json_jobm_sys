

cat(paste0("  ", "\n"))
cat(paste0("###################################################################################", "\n"))
cat(paste0("=====  eqCCvrg Column values test   ========================", "\n"))
cat(paste0("===================================================================================", "\n"))
cat(paste0("  ", "\n"))


cat("Checking eqCCvrg tables for certain columns/values that should not exist  ----------- \n")

for(ctry in countries) {
  
  cat(paste0( toupper(ctry) , "\n"))
  
  ck = grep(paste0(prl, ctry, "vrgsec"), all_tables[Country == ctry])
  if(length(ck) == 0){
    cat( cat(paste0("\t ", paste0(prl, ctry, "vrgsec") , " Not in GeoHaz \n")))
  } else {
    
    Test10_query1 = paste0("SELECT count(*) FROM ",prl, ctry, "vrgsec where GWD = 0")
    Ct1 = data.table(sqlQuery(ghc,as.is=TRUE, Test10_query1 ))
    
    if( Ct1 > 0){
      cat( cat(paste0("\t Fail! ",  "Records with GWD = 0 in ", prl, ctry ,"vrgsec table. \n")))
      cat( cat(paste0("\t       ",  "These records should be changed to GWD = 0.1 \n")))
    } else {
      cat( cat(paste0("\t Pass! ",  "No records with GWD = 0 in ", prl, ctry ,"vrgsec table. \n")))
      
    }
    
  }

  ## ------------------------------------------------------
  
  
  ck = grep(paste0(prl, ctry, "vrgland"), all_tables[Country == ctry])
  if(length(ck) == 0){
    cat( cat(paste0("\t ", paste0(prl, ctry, "vrgland") , " Not in GeoHaz \n")))
  } else {
    
    Test10_query2 = paste0("SELECT count(*) FROM ",prl, ctry, "vrgland where HAZ = 0")
    Ct2 = data.table(sqlQuery(ghc,as.is=TRUE, Test10_query2 ))
    
    if( Ct2 > 0){
      cat( cat(paste0("\t Fail! ",  "Records with HAZ = 0 in ", prl, ctry ,"vrgland table. \n")))
    } else {
      
      cat( cat(paste0("\t Pass! ",  "No records with HAZ = 0 in ", prl, ctry ,"vrgland table. \n")))
    }
    
  }
  
  ## ------------------------------------------------------
  
  ck = grep(paste0(prl, ctry, "vrgsoil"), all_tables[Country == ctry])
  if(length(ck) == 0){
    cat( cat(paste0("\t ", paste0(prl, ctry, "vrgsoil") , " Not in GeoHaz \n")))
  } else {
    
    Test10_query3 = paste0("SELECT count(*) FROM ",prl, ctry, "vrgsoil where HAZ = 0")
    Ct3 = data.table(sqlQuery(ghc,as.is=TRUE, Test10_query3 ))
    
    if( Ct3 > 0){
      cat( cat(paste0("\t Fail! ",  "Records with HAZ = 0 in ", prl, ctry ,"vrgsoil table. \n")))
    } else {
      
      cat(paste0("\t Pass! ",  "No records with HAZ = 0 in ", prl, ctry ,"vrgsoil table. \n"))
    }
    
    }
    

  ## ------------------------------------------------------
  
  
  ck = grep(paste0(prl, ctry, "vrgliq"), all_tables[Country == ctry])
  if(length(ck) == 0){
    cat( cat(paste0("\t ", paste0(prl, ctry, "vrgliq") , " Not in GeoHaz \n")))
  } else {
    
    Test10_query4 = paste0("SELECT count(*) FROM ",prl, ctry, "vrgliq where HAZ = 0")
    Ct4 = data.table(sqlQuery(ghc,as.is=TRUE, Test10_query4 ))
    
    if( Ct4 > 0){
      cat(paste0("\t Fail! ",  "Records with HAZ = 0 in ", prl, ctry ,"vrgliq table. \n"))
    } else {
      
      cat(paste0("\t Pass! ",  "No records with HAZ = 0 in ", prl, ctry ,"vrgliq table. \n"))
    }
    
  }
  

  ## ------------------------------------------------------
  
  
  ck = grep(paste0(prl, ctry, "vrgsoilperiod"), all_tables[Country == ctry])
  if(length(ck) == 0){
    cat( cat(paste0("\t ", paste0(prl, ctry, "vrgsoilperiod") , " Not in GeoHaz \n")))
  } else {
    
    Test10_query5 = paste0("SELECT count(*) FROM ",prl, ctry, "vrgsoilperiod where SOILVS = 0")
    Ct5 = data.table(sqlQuery(ghc,as.is=TRUE, Test10_query5 ))
    
    if( Ct5 > 0){
      cat(paste0("\t Fail! ",  "Records with SOILVS = 0 in ", prl, ctry ,"vrgsoilperiod table. \n"))
    }  else {
      
      cat(paste0("\t Pass! ",  "No records with SOILVS s= 0 in ", prl, ctry ,"vrgsoilperiod table. \n"))
    }
    
    ## ------------------------------------------------------
    
    Test10_query6 = paste0("SELECT count(*) FROM ",prl, ctry, "vrgsoilperiod where SOILVS >= 1000 and SOILPERIOD > 0")
    Ct6 = data.table(sqlQuery(ghc,as.is=TRUE, Test10_query6 ))
    
    if( Ct6 > 0){
      cat(paste0("\t Warning! ", Ct6  ," records with (SOILVS >= 1000 & SOILPERIOD > 0) in ", prl, ctry ,"vrgsoilperiod table. \n"))
    } else {
      cat(paste0("\t Pass! ", "No records with (SOILVS >= 1000 & SOILPERIOD > 0) in ", prl, ctry ,"vrgsoilperiod table. \n"))
      
    }
    
    ## ------------------------------------------------------
    
    Test10_query7 = paste0("SELECT count(*) FROM ",prl, ctry, "vrgsoilperiod where SOILPERIOD > 0 and BASINID = 0")
    Ct7 = data.table(sqlQuery(ghc,as.is=TRUE, Test10_query7 ))
    
    if( Ct7 > 0){
      cat(paste0("\t Warning! ", Ct7, " records with (SOILPERIOD > 0 & BASINID = 0) in ", prl, ctry ,"vrgsoilperiod table. \n"))
    } else {
      cat(paste0("\t Pass! ",  "No records with (SOILPERIOD > 0 & BASINID = 0) in ", prl, ctry ,"vrgsoilperiod table. \n"))
    } 
    
    
  }

  
  ck = grep(paste0(prl, ctry, "pc"), all_tables[Country == ctry])
  if(length(ck) == 0){
    cat( cat(paste0("\t ", paste0(prl, ctry, "pc") , " Not in GeoHaz \n")))
  } else {
    
    Test10_query8 = paste0("SELECT count(*) FROM ",prl, ctry, "pc where SOILVS >= 1000 and SOILPERIOD > 0 ")
    Ct8 = data.table(sqlQuery(ghc,as.is=TRUE, Test10_query8 ))
    
    if( Ct8 > 0){
      cat(paste0("\t Warning! ", Ct8 ,"records with (SOILVS >= 1000 & SOILPERIOD > 0) in ", prl, ctry ,"pc table. \n"))
    } else {
      cat(paste0("\t Pass! ", "No records with (SOILVS >= 1000 & SOILPERIOD > 0) in ", prl, ctry ,"pc table. \n"))
    }
    
    ##--------------------------------------------------------
    
    Test10_query9 = paste0("SELECT count(*) FROM ",prl, ctry, "pc where SOILPERIOD > 0 and BASINID = 0 ")
    Ct9 = data.table(sqlQuery(ghc,as.is=TRUE, Test10_query9 ))
    
    if( Ct9 > 0){
      cat(paste0("\t Warning! ", Ct9 ," records with (SOILPERIOD > 0 and BASINID = 0) in ", prl, ctry ,"pc table. \n"))
    } else {
      cat(paste0("\t Pass! ", "No records with (SOILPERIOD > 0 and BASINID = 0) in ", prl, ctry ,"pc table. \n"))
      
    }
    
    
  }
  
  cat(paste0("\t ----- ------ ------ ------ ------ ------ ------ ", "\n"))  
  
  
  
  
}