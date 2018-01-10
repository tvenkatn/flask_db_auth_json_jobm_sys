from flask import Flask, url_for, redirect, render_template, request
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.sql import func
import datetime
import psycopg2
import subprocess
import json

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI']='postgresql://postgres:welcome@localhost/flaskApp1'
db=SQLAlchemy(app)
#db.create_all()

## psycopg2
def getPostName(nameHere):
    conn = psycopg2.connect("dbname='flaskApp1' user ='postgres' host= 'localhost' password='welcome'")
    cur = conn.cursor()
    cur.execute("""select weight_ from bmi where name_ = '%s' limit 1""" % nameHere)
    rows = cur.fetchall()
    return rows[0]

class Bmi(db.Model):
    __tablename__="bmi"
    id=db.Column(db.Integer, primary_key=True)
    name_=db.Column(db.String(120), unique=True)
    weight_=db.Column(db.Numeric)
    height_=db.Column(db.Numeric)
    queryTime = db.Column(db.DateTime, default=datetime.datetime.now)

    def __init__(self, name_, weight_, height_):
        self.name_=name_
        self.weight_=weight_
        self.height_=height_

@app.route("/", methods=["GET", "POST"])
def main():
    return 'Hello World !'

@app.route('/HH<name>')
def hello_name(name):
   return 'Hello %s!' % name
#http://127.0.0.1:5000/HHsri
#HH is case sensitive. URLs should be case sensitive!!
#https://stackoverflow.com/questions/28801707/case-insensitive-routing-in-flask

@app.route('/ddtest', methods=["GET", "POST"])
def getDropDown():
    colours = ['Red', 'Blue', 'Black', 'Orange']
    rows = db.session.query(Bmi)
    nm = []
    for row in rows:
        nm.append(row.name_)
    colours = nm
    if request.method == "POST" and 'thisColor' in request.form:
#        return "the selected color is %s" % request.form.get("thisColor")
        return render_template('allUsers.html', colours=colours, selColor = request.form.get("thisColor"))
    else:
        return render_template('allUsers.html', colours=colours)
    
@app.route('/defTest', methods=["GET", "POST"])
def defTest():
    from defs import getColors, getNames
    colours = ['Red', 'Blue', 'Black', 'Orange']
#    colours = getColors()
    colours = getNames()
    if request.method == "POST" and 'thisColor' in request.form:
#        return "the selected color is %s" % request.form.get("thisColor")
        return render_template('allUsers.html', colours=colours, selColor = request.form.get("thisColor"))
    else:
        return render_template('allUsers.html', colours=colours)


@app.route('/runR', methods=["GET", "POST"])
def runR():
    colours = ['Red', 'Blue', 'Black', 'Orange']
    if request.method == "POST" and 'thisColor' in request.form:
#        return "the selected color is %s" % request.form.get("thisColor")
        R = subprocess.call(["cmd", "/c", "Rscript","D:/Srinivas/work/20180105_flask_db_auth_json/rFiles/createFiles.r", """"%s""" % request.form.get("thisColor")])    
        return render_template('allUsers.html', colours=colours, selColor = request.form.get("thisColor"))
    else:
        return render_template('allUsers.html', colours=colours)

@app.route('/rlrunner', methods=["GET", "POST"])
def rlrunner():
    colours = ['Red', 'Blue', 'Black', 'Orange']
    if request.method == "POST" and 'thisColor' in request.form:
#        return "the selected color is %s" % request.form.get("thisColor")
        R = subprocess.call(["cmd", "/c", "cd", "D:/main/test", "\&\&", "Rscript","N:/APPLICS/EngTools/R_packages/EDS_Runner/EDS_Runner_JPEQ.R", """%s""" % "D:/main/lib", """%s""" % "runMTH=1", """%s""" % "calcAAL=0", """%s""" % "EQ"])
        return render_template('allUsers.html', colours=colours, selColor = request.form.get("thisColor"))
    else:
        return render_template('allUsers.html', colours=colours)    
    
@app.route('/bmi', methods=["GET", "POST"])
def bmi():
    myName = ""
    myWeight = 0
    myHeight = 1
    db.create_all()
    if request.method == "POST" and 'userName' in request.form:
        myName = request.form.get("userName")
        myWeight = float(request.form.get("userWeight"))
        myHeight = float(request.form.get("userHeight"))
        if db.session.query(Bmi).filter(Bmi.name_ == myName).count()== 0:
            bmi=Bmi(myName, myWeight, myHeight)
            db.session.add(bmi)
            db.session.commit()
            return render_template('bmi.html', name = myName, bmi = round(myWeight/(myHeight*myHeight),1))
        else:
            row = db.session.query(Bmi).filter(Bmi.name_ == myName)
            nm = row.first().name_
            wt = row.first().weight_
            ht = row.first().height_
            bmiHere = round(wt/(ht*ht),1)
            jOut = {"name": nm,
                   "weight": str(wt),
                   "height": str(ht)
                   }
            # string conversion is required for above decimal values coz decimals are not JSON serializable
            with open('data.json', 'w') as outfile:
                json.dump(jOut, outfile)
            return redirect(url_for('getDropDown'))
#            return json.dumps(jOut)
#            return "This name: %s already exists. The BMI is %s" % (nm, bmiHere)
#            return str(getPostName(myName))
    else:
        return render_template('bmi.html')


if __name__ == '__main__':
    app.run(host= '0.0.0.0', port = 5005, debug=True)