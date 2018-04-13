

## Test for Columns' ranges

cat(paste0("  ", "\n"))
cat(paste0("###################################################################################", "\n"))
cat(paste0("=====  Column Ranges Test   =======================================================", "\n"))
cat(paste0("===================================================================================", "\n"))
cat(paste0("  ", "\n"))

# For Landslide columns
if(prl == 'eq' ){
  # cat(paste0("===========================", "\n"))
  # cat(paste0("Column Ranges Test   \n"))
  
  RangeTypes = c("LandslideRanges", "LiquefactionRanges") 
  #RangeTypes = c( 'LiquefactionRanges') 
  
  for(rangeType in RangeTypes ){
    
    cat(paste0("Check column ranges for ", rangeType ,"\n"))
    
    for(ctry in countries){
      
      cat(paste0("\t ", toupper(ctry) , ": \n"))
      cpt_ctry = toupper(ctry)
      
      RangeList = CF[[rangeType]]
      ColRanges = RangeList[cpt_ctry]
      
      if(length(ColRanges[[1]]) == 1){
        map2ctry = ColRanges[[1]]
        ColRanges = RangeList[map2ctry]
      }
      
      n_col = length(ColRanges[[1]])
      for( c in 1: n_col){
        col_name = attributes(ColRanges[[1]][c])$names
        col_rang_N = length(ColRanges[[1]][c][[1]])
        col_min = ColRanges[[1]][c][[1]][1]
        col_max = ColRanges[[1]][c][[1]][2]
        if(col_rang_N == 3){
          col_special = ColRanges[[1]][c][[1]][3]
        }
        
        str_for_qry = paste("TABLE_NAME like '",prl,expcted_ctrys, sep="", collapse = "%' or ")
        str_for_qry = paste(str_for_qry, "%'", sep="")
        
        col_query = paste0( "SELECT COLUMN_NAME, TABLE_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME LIKE '",col_name,"'")
        dt = data.table(sqlQuery(ghc, as.is = TRUE,col_query ))
        #dt = dt[grep(eval(ctry), TABLE_NAME)]
        dt = dt[grep(eval(ctry), substr(TABLE_NAME,3,4))]
        dt = dt[grep(eval(prl), substr(TABLE_NAME,1,2))]
        
        for(i in 1:nrow(dt)){
          
          tb_here = dt[i]$TABLE_NAME
          if(all_tables[TABLE_NAME == dt[i]$TABLE_NAME ]$Ct_records == 0){
            # cat(paste0("\t ", "Warning!  GeoHazard's ", dt[i]$TABLE_NAME ," table is empty" ,"\n"))
            
          }else {
            
            check_qry = paste0("select distinct ",col_name," as var from ", dt[i]$TABLE_NAME )
            chck_dt = data.table(sqlQuery(ghc, as.is = TRUE, check_qry ))
            if( nrow(chck_dt) == 1){
              cat(paste0("\t Skip test: all records of ", col_name ," in ", dt[i]$TABLE_NAME , " have same value ",chck_dt[1]$var, "\n" ))
            } else {
  
              query_min = paste0("select min(",col_name,") from ", dt[i]$TABLE_NAME )
              query_max = paste0("select max(",col_name,") from ", dt[i]$TABLE_NAME )
              
              if(col_rang_N == 3){
                query_min = paste0("select min(",col_name,") from ", dt[i]$TABLE_NAME, " where ",  col_name, " != ", col_special )
                query_max = paste0("select max(",col_name,") from ", dt[i]$TABLE_NAME, " where ",  col_name, " != ", col_special )
              }
              db_col_min = as.numeric(data.table(sqlQuery(ghc, as.is = TRUE,query_min )))
              db_col_max = as.numeric(data.table(sqlQuery(ghc, as.is = TRUE,query_max )))
              
              if( (db_col_min < col_min) | (db_col_max > col_max)){
                
                query_over = paste0("select count(",col_name,") from ", dt[i]$TABLE_NAME,
                                    " where ( ",  col_name, " < ", col_min,  " or ", col_name, " > ", col_max, ")"  )
                
                if(col_rang_N == 3){
                  query_over = paste0("select count(",col_name,") from ", dt[i]$TABLE_NAME, " where ",  col_name, " != ", col_special,
                                      " and ( ",  col_name, " < ", col_min,  " or ", col_name, " > ", col_max, ")"  )
                }
                
                Nct =  as.numeric(data.table(sqlQuery(ghc, as.is = TRUE,query_over )))
                
                cat(paste0("\t ", "Warning! ", dt[i]$TABLE_NAME," ", col_name ," values are NOT in right range. " ,"\n"))
                cat(paste0("\t\t ", " Counts of beyond range: ", Nct ,"\n"))
                cat(paste0("\t\t ", " minVal: ", round(db_col_min,2) ,",\t",  " maxVal: ", round(db_col_max,2) ,"\n"))

              }else {
                
                #cat(paste0("\t ", "Pass! ", dt[i]$TABLE_NAME," ", col_name ," values are in right range. " ,"\n"))
                #cat(paste0("\t ", "Pass!  GeoHazard's ", dt[i]$TABLE_NAME," ", col_name ," values are in right range. " ,"\n"))
                
              }
              
              
              
            }
                                 
            

            
          }
          
          
        }
        
      }
      
      cat(paste0("----- ----- ----- ----- ----- ----- -----", "\n"))
    }
    
    
  }
  
  
  
  
  
}




