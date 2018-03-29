import os, re

HDReg_wd = r'\\cawd16744\HD_testRegression'
HDReg_repFormat = "allReports.csv$"

def getAllFiles(fPath, fPat):
    """
    this is equivalent of glob.glob with more
    control to me
    """
    fl = os.listdir(os.path.join(HDReg_wd, 'reports'))
    regex = re.compile(HDReg_repFormat)
    fList = []
    fltrFiles = filter(regex.search, fl)
    for f in fltrFiles:
        fList.append(f)
    return fList
