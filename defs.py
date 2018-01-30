from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.sql import func
from app import db
import pyodbc
import os

ALLOWED_EXTENSIONS = set(['txt','dat','csv','xml','zip','bat'])

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

def allowed_file(filename):
    return '.' in filename and \
        filename.rsplit('.', 1)[1] in ALLOWED_EXTENSIONS


def mkDirs(bPath, dirName):
    dName = os.path.join(bPath, dirName)
    if not os.path.exists(dName):
        os.makedirs(dName)
    return dName