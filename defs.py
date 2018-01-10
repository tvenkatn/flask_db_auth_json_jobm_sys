from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.sql import func
from app import db


def getColors():
    return ["Cyan", "Magenta", "Yello", "Key"]

def getNames():
    rows = db.session.query(Bmi)
    nm = []
    for row in rows:
        nm.append(row.name_)
    return nm

