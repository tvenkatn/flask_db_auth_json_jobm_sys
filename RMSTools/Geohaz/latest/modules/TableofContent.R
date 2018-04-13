#Developed by Mohammad Razavi June-2016


#rm(list=ls())
cat("\014")
cat("\n")
c=Sys.time()


cwd <- getwd()

## GO TO TOP STATEMENT
#<h2 id="top">TABLE OF CONTENTS:</h1>
# <a href="#top">Go to top</a>

htmlFile2Read = paste0("log/Main_", mdl, ".html")  #CYC: for multiple Models' tests

# Read the html file
#htmlread = readLines("log/Main.html",-1)
htmlread = readLines(htmlFile2Read,-1)  #CYC: for multiple Models' tests


#Find all recodes with h4- considering all titles are written in h4
headerindex=grep('<h4>',htmlread)


#htmlread[headerindex]
contents<- gsub("<h4>","" ,htmlread[headerindex])
contents<- gsub("</h4>","" ,contents)

## add index id to titles
j=1
for (i in headerindex) {
  htmlread[i]<-gsub("<h4>",paste0("<h4 id='",toString(j),"'>") ,htmlread[i])
  j=j+1}



## add go to top after each test
for (i in headerindex) {
  htmlread[i+1]<-paste0('<a href="#top">Go to top</a>')
  }




##Generate a new html file with timestamp
tStamp <- as.character(format(Sys.time(), "%Y%m%d_%Hh%Mm%Ss"))

if(file.exists(paste0("log/Report_",tStamp,".html"))){
  reportCon <- file(paste0("log/",mdl,"_GeoHaz_Report_",tStamp,".html"),open="a")
}else {
  reportCon <- file(paste0("log/",mdl,"_GeoHaz_Report_",tStamp,".html"),open="a")}


## Find and Color code the Pass, Warning, and Fail in the rep
indexPass=grep("Pass!",htmlread)
htmlread[indexPass]<- gsub("Pass!", '<b><font color="green">Pass!</font></b>',htmlread[indexPass])


indexFail=grep("Fail!",htmlread)
htmlread[indexFail]<- gsub("Fail!", '<b><font color="red">Fail!</font></b>',htmlread[indexFail])

indexwarn=grep("Warning!",htmlread)
htmlread[indexwarn]<- gsub("Warning!", '<b><font color="orange">Warning!</font></b>',htmlread[indexwarn])


## find tests with warning, Pass, and Fails so we can color code the table of contents

Contentscolor=c()

Contentscolor[1]='black'
for (i in 2: (length(headerindex))){
  if(i==length(headerindex)){endindex=length(htmlread)} else {endindex=headerindex[i+1]}
  indexPass=grep("Pass",htmlread[headerindex[i]:endindex])
  if (length(indexPass)!=0){Contentscolor[i]='green'}
  indexwarn=grep("Warning",htmlread[headerindex[i]:endindex])
  if (length(indexwarn)!=0){Contentscolor[i]='orange'}
  indexFail=grep("Fail",htmlread[headerindex[i]:endindex])
  if (length(indexFail)!=0){Contentscolor[i]='red'}
}


## Create the Table of Contents
Tableofcontent=paste0('
<nav role="navigation" class="table-of-contents">
<h3 id="top">TABLE OF CONTENTS:</h1>
<ul>
')

for (i in 1: length(contents)){
Tableofcontent=paste0(Tableofcontent,'<li><a href="#',toString(i),'">','<font color="',Contentscolor[i],'">',contents[i],"!</font></a></li>"," ")
}

Tableofcontent=paste0(Tableofcontent,'</ul>
</nav>')


## Write the new html file
cat(paste0(htmlread[1:headerindex[1]-1],"\n"), file = reportCon, append = TRUE)
cat(paste0(Tableofcontent,"\n"), file = reportCon, append = TRUE)
cat(paste0(htmlread[headerindex[1]:length(htmlread)],"\n"), file = reportCon, append = TRUE)


## Close the file
close(reportCon)
