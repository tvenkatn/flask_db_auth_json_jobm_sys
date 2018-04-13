import pyodbc

ser = 'ca1mdtools01'
mydb = 'RMS_VULNERABILITY_EUFL_official'

def getdbVCCs(ser, mydb):
    command = ["""SELECT * FROM sys.tables where name like '%vcc%'"""]
    vccs = []
    cnn = pyodbc.connect(driver='{SQL Server}', host=ser, database=mydb, Trusted_Connection='yes')
    # cnn = pyodbc.connect(driver='{SQL Server}', host=ser, user='sa', password='Rmsuser!')
    cursor = cnn.cursor()
    cursor.execute(command[0])
    rows = cursor.fetchall()
    for row in rows:
        a = row[0]
        if len(a) == 7:
            vccs.append(a)
    return vccs

def getCountryPerils(ser, mydb):
    vccs = getdbVCCs(ser, mydb)
    perilCountries = [(x[0:2], x[-2:]) for x in vccs]
    return perilCountries