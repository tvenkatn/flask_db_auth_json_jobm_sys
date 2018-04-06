import os, re

def getAllFiles(fPath, fPat):
    """
    this is equivalent of glob.glob with more
    control to me
    """
    fl = os.listdir(os.path.join(fPath, "reports"))
    regex = re.compile(fPat)
    fList = []
    fltrFiles = filter(regex.search, fl)
    for f in fltrFiles:
        fList.append(f)
    return fList

