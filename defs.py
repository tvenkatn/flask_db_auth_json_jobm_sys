from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.sql import func
from app import db
import pyodbc
import os
import json

ALLOWED_EXTENSIONS = set(['txt','dat','csv','xml','zip','bat','yml'])

def getColors():
    return ["Cyan", "Magenta", "Yello", "Key"]

def getNames():
    rows = db.session.query(Bmi)
    nm = []
    for row in rows:
        nm.append(row.name_)
    return nm

def getVulnDbs(ser):
    command = ["""SELECT name FROM   sys.databases WHERE  CASE WHEN state_desc = 'ONLINE' THEN OBJECT_ID(QUOTENAME(name) + '.[dbo].[cghs]', 'U') END IS NOT NULL""", """select name from sys.databases where name like 'RMS_VULN%'"""]
    vulns = []
    cnn = pyodbc.connect(driver='{SQL Server}', host=ser, Trusted_Connection='yes')
    # cnn = pyodbc.connect(driver='{SQL Server}', host=ser, user='sa', password='Rmsuser!')
    cursor = cnn.cursor()
    cursor.execute(command[1])
    rows = cursor.fetchall()
    for row in rows:
        a = row[0]
        vulns.append(a)
    return vulns

def getGeohazDbs(ser):
    command = ["""SELECT name FROM   sys.databases WHERE  CASE WHEN state_desc = 'ONLINE' THEN OBJECT_ID(QUOTENAME(name) + '.[dbo].[cghs]', 'U') END IS NOT NULL""", """select name from sys.databases where name like 'RMS_Geoh%'"""]
    geohazs = []
    cnn = pyodbc.connect(driver='{SQL Server}', host=ser, Trusted_Connection='yes')
    # cnn = pyodbc.connect(driver='{SQL Server}', host=ser, user='sa', password='Rmsuser!')
    cursor = cnn.cursor()
    cursor.execute(command[1])
    rows = cursor.fetchall()
    for row in rows:
        a = row[0]
        geohazs.append(a)
    return geohazs

def getEDMDbs(ser):
    command = ["""SELECT name FROM   sys.databases WHERE  CASE WHEN state_desc = 'ONLINE' THEN OBJECT_ID(QUOTENAME(name) + '.[dbo].[cghs]', 'U') END IS NOT NULL""", """select name from sys.databases where name like '%EDM%' or name like '%EED%' or name like '%IED%' and state_desc = 'ONLINE'"""]
    edms = []
    cnn = pyodbc.connect(driver='{SQL Server}', host=ser, Trusted_Connection='yes')
    # cnn = pyodbc.connect(driver='{SQL Server}', host=ser, user='sa', password='Rmsuser!')
    cursor = cnn.cursor()
    cursor.execute(command[1])
    rows = cursor.fetchall()
    for row in rows:
        a = row[0]
        edms.append(a)
    return edms

def getEDMPorts(ser, EDM):
    command = ["""select cast(PORTINFOID as varchar) + '_' + PORTNAME from [""" + EDM + """].[dbo].[portinfo]"""]
    ports = []
    cnn = pyodbc.connect(driver='{SQL Server}', host=ser, Trusted_Connection='yes')
    cursor = cnn.cursor()
    cursor.execute(command[0])
    rows = cursor.fetchall()
    # for row in rows:
    #     a = row[0]
    #     ports.append(a)
    # return ports
    allRecords = []
    record = {}
    for row in rows:
        record['port'] = row[0]
        allRecords.append(json.dumps(record))
    return allRecords
def LocsPorts(ser, EDM, port):
    command = ["""select latitude, longitude, locid from [""" + EDM + """].[dbo].[loc] where accgrpid in (select accgrpid from [""" + EDM + """].[dbo].[portacct] where portinfoid = """ + str(port) + """)"""]
    command2 = [
        """select latitude, longitude, a.locid, exposure from (select latitude, longitude, locid, accgrpid from [""" + EDM + """].[dbo].[loc])
    a
    inner join (select locid, sum(valueamt) as exposure from [""" + EDM + """].[dbo].[loccvg] group by locid) b
    on a.locid = b.locid
    where accgrpid in (select accgrpid from [""" + EDM + """].[dbo].[portacct] where portinfoid = """ + str(
            port) + """)"""
        ]

    cnn = pyodbc.connect(driver='{SQL Server}', host=ser, Trusted_Connection='yes')
    cursor = cnn.cursor()
    cursor.execute(command2[0])
    rows = cursor.fetchall()
    allRecords = []
    record = {}
    for row in rows:
        record['lat'] = row[0]
        record['lon'] = row[1]
        record['title'] = row[2]
        record['exposure'] = row[3]
        allRecords.append(json.dumps(record))
    return allRecords

def allowed_file(filename):
    return '.' in filename and \
        filename.rsplit('.', 1)[1] in ALLOWED_EXTENSIONS


def mkDirs(bPath, dirName):
    dName = os.path.join(bPath, dirName)
    if not os.path.exists(dName):
        os.makedirs(dName)
    return dName
