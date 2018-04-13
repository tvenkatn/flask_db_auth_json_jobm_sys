# if(nchar(gsub("^\\s+|\\s+$", "", configDir))==0) {configDir<-getwd()}
# #if(nchar(gsub("^\\s+|\\s+$", "", configName))==0) {configName<-"StocConfig.txt"}
# con=file(paste0(configDir,"/",configName),open="r")
# line=readLines(con)
# commentMark<-"//"

# for(i in 1:length(line)) {
    # #if(grepl(line[i],commentMark))
    # abcd<-gregexpr(pattern=commentMark,line[i])
    # pos<-abcd[[1]][1]
    # if(pos==1){line[i]<-""}
    # else if (pos>1) {line[i]<-strsplit(line[i],commentMark)[[1]][1]}
    # else{}
# }

# close(con)


readJSON = function(configDir, configName) {
  
  #configDir<-getwd()
  con=file(paste0(configDir,"/",configName),open="r")
  line=readLines(con)
  commentMark<-"//"
  
  for(i in 1:length(line)) {
      #if(grepl(line[i],commentMark))
      abcd<-gregexpr(pattern=commentMark,line[i])
      pos<-abcd[[1]][1]
      if(pos==1){line[i]<-""}
      else if (pos>1) {line[i]<-strsplit(line[i],commentMark)[[1]][1]}
      else{}
  }
     
  close(con)
  return(line)

}