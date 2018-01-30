userArgs <- commandArgs(trailingOnly = TRUE)
userArgs2 <- commandArgs(trailingOnly = FALSE)
thisCodeDir <- dirname(strsplit(userArgs2[4],'=')[[1]][2])

nameHere <- userArgs[1]

setwd(thisCodeDir)
conLog <- file(paste0(nameHere, "_e2e_runLog", as.character(format(Sys.time(), "%Y%m%d_%Hh%Mm%Ss")),".txt") , open = 'at')
cat(paste0("User:",Sys.info()["user"][[1]],"; Machine:", Sys.info()["nodename"][[1]],"; Time:",Sys.time(),"\n"), file = conLog, append = TRUE)
close(conLog)

Sys.sleep(20)

conLog <- file(paste0(nameHere, "_e2e_runLog", as.character(format(Sys.time(), "%Y%m%d_%Hh%Mm%Ss")),".txt") , open = 'at')
cat(paste0("User:",Sys.info()["user"][[1]],"; Machine:", Sys.info()["nodename"][[1]],"; Time:",Sys.time(),"\n"), file = conLog, append = TRUE)
close(conLog)


