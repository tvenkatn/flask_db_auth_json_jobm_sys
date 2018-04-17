import os, re, csv

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

def getCsvNCol(fn_):
    reader = csv.reader(open(fn_, "r"))
    lenRead = 0
    for row in reader:
        lenRead = len(row)
        break
    return lenRead