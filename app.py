import os
from flask import Flask, url_for, redirect, render_template, request, flash, session, jsonify, json, send_from_directory
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.sql import func
import datetime
import psycopg2
import subprocess
import json
from werkzeug import generate_password_hash, check_password_hash, secure_filename
from flask_wtf import Form
from wtforms import TextField, TextAreaField, SubmitField, validators, ValidationError, PasswordField
from flask_login import LoginManager, login_user, login_required, logout_user
from celery import Celery

ALLOWED_EXTENSIONS = set(['txt','dat','csv','xml','zip','bat','yml'])
UPLOAD_FOLDER = './rFiles/rlr/'

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI']='postgresql://postgres:welcome@localhost/flaskApp1'
db=SQLAlchemy(app)
app.secret_key = 'CatchMe, if yOU Ca nn~!'
login_manager = LoginManager()
login_manager.init_app(app)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['CELERY_BROKER_URL'] = 'redis://localhost:6379/0'
app.config['CELERY_RESULT_BACKEND'] = 'redis://localhost:6379/0'


## psycopg2
def getPostName(nameHere):
    conn = psycopg2.connect("dbname='flaskApp1' user ='postgres' host= 'localhost' password='welcome'")
    cur = conn.cursor()
    cur.execute("""select weight_ from bmi where name_ = '%s' limit 1""" % nameHere)
    rows = cur.fetchall()
    return rows[0]

## for models.py
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
        
class User(db.Model):
    __tablename__ = 'users'
    uid = db.Column(db.Integer, primary_key = True)
    firstname = db.Column(db.String(100))
    lastname = db.Column(db.String(100))
    email = db.Column(db.String(120), unique=True)
    pwdhash = db.Column(db.String(154))

    def __init__(self, firstname, lastname, email, password):
        self.firstname = firstname.title()
        self.lastname = lastname.title()
        self.email = email.lower()
        self.set_password(password)

    def set_password(self, password):
        self.pwdhash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.pwdhash, password)

## form templates
class SignupForm(Form):
    firstname = TextField("First name",  [validators.Required("Please enter your first name.")])
    lastname = TextField("Last name",  [validators.Required("Please enter your last name.")])
    email = TextField("Email",  [validators.Required("Please enter your email address."), validators.Email("Please enter your email address.")])
    password = PasswordField('Password', [validators.Required("Please enter a password.")])
    submit = SubmitField("Create account")

    def __init__(self, *args, **kwargs):
        Form.__init__(self, *args, **kwargs)
 
    def validate(self):
        if not Form.validate(self):
            return False
        user = db.session.query(User).filter_by(email = self.email.data.lower()).first()
        if user:
            self.email.errors.append("That email is already taken")
            return False
        else:
            return True

@app.route('/signup', methods=['GET', 'POST'])
def signup():
    if 'email' in session:
        return redirect(url_for('profile'))
    form = SignupForm()
    if request.method == 'POST':
        if form.validate() == False:
            return render_template('signup.html', form=form)
        else:
            newuser = User(form.firstname.data, form.lastname.data, form.email.data, form.password.data)
            db.session.add(newuser)
            db.session.commit()
            session['email'] = newuser.email
            return redirect(url_for('profile'))

    elif request.method == 'GET':
        db.create_all()
        return render_template('signup.html', form=form)

@app.route('/profile')
def profile():
    if 'email' not in session:
        return redirect(url_for('signup'))
    user = User.query.filter_by(email = session['email']).first()
    if user is None:
        return redirect(url_for('signup'))
    else:
        return render_template('profile.html')

@app.route('/signout')
def signout():
    if 'email' not in session:
        return redirect(url_for('signup'))
    session.pop('email', None)
    return redirect(url_for('signup'))

@app.route("/", methods=["GET", "POST"])
def main():
    return 'Hello World !'

@app.route('/HH<name>')
def hello_name(name):
    return 'Hello %s!' % name
#http://127.0.0.1:5000/HHsri
#HH is case sensitive. URLs should be case sensitive!!
#https://stackoverflow.com/questions/28801707/case-insensitive-routing-in-flask

celery = Celery(app.name, broker=app.config['CELERY_BROKER_URL'])
celery.conf.update(app.config)

@celery.task
def runRinBack(thisCol):
    subprocess.call(["cmd", "/c", "Rscript", "D:/Srinivas/work/20180105_flask_db_auth_json/rFiles/createFiles.r",""""%s""" % thisCol])

def runRinBackNC(thisCol):
    subprocess.call(["cmd", "/c", "Rscript", "D:/Srinivas/work/20180105_flask_db_auth_json/rFiles/createFiles.r",""""%s""" % thisCol])
    return("done")


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

@app.route('/getVulns', methods=["GET", "POST"])
def getVulns():
    # serList = ["ca-md1-02","ca1mdrlcsint02","ca1mdmcert30","ca1mdtools01","ca1mdnaeq18"];
    with open('data/serList.csv', 'r') as f:
        serList = [line.rstrip() for line in f]
    if request.method == "POST" and 'server' in request.form:
        from defs import getVulnDbs
        vulns = getVulnDbs(request.form.get("server"))
        # return "the selected server is %s" % ser
        return render_template('allVulns.html', serList=serList, selVuln=vulns)
    else:
        return render_template('allVulns.html', serList=serList)

@app.route('/runR', methods=["GET", "POST"])
def runR():
    # if 'email' not in session:
    #     return redirect(url_for('signup'))
    colours = ['Red', 'Blue', 'Black', 'Orange']
    if request.method == "POST" and 'thisColor' in request.form:
#        return "the selected color is %s" % request.form.get("thisColor")
        task = runRinBack.delay(request.form.get("thisColor"))
        # task = runRinBack.apply_async(args=[request.form.get("thisColor")], countdown=1)
#         R = runRinBackNC(request.form.get("thisColor"))
#         R = subprocess.call(["cmd", "/c", "Rscript", "D:/Srinivas/work/20180105_flask_db_auth_json/rFiles/createFiles.r", """"%s""" % request.form.get("thisColor")])
        return render_template('allUsers.html', colours=colours, selColor = request.form.get("thisColor") + ". Task ID: " + task.id + ". Location: " + url_for('taskstatus',
                                                  task_id=task.id))
    else:
        return render_template('allUsers.html', colours=colours)

@app.route('/status/<task_id>')
def taskstatus(task_id):
    task = runRinBack.AsyncResult(task_id)
    # if task.state == 'PENDING':
    #     # job did not start yet
    #     response = {
    #         'status': 'Pending...'
    #     }
    # elif task.state != 'FAILURE':
    #     response = {
    #         'status': "FAILURE..."
    #     }
    # else:
    #     # something went wrong in the background job
    #     response = {
    #         'status': str(task.info),  # this is the exception raised
    #     }
    return jsonify(task.state)

@app.route('/rlrunner', methods=["GET", "POST"])
def rlrunner():
    colours = ['Red', 'Blue', 'Black', 'Orange']
    if request.method == "POST" and 'thisColor' in request.form:
#        return "the selected color is %s" % request.form.get("thisColor")
        R = subprocess.call(["cmd", "/c", "cd", "D:/main/test", "\&\&", "Rscript","N:/APPLICS/EngTools/R_packages/EDS_Runner/EDS_Runner_JPEQ.R", """%s""" % "D:/main/lib", """%s""" % "runMTH=1", """%s""" % "calcAAL=0", """%s""" % "EQ"])
        return render_template('allUsers.html', colours=colours, selColor = request.form.get("thisColor"))
    else:
        return render_template('allUsers.html', colours=colours)    

@app.route('/rlr', methods=["GET", "POST"])
def rlr():
    colours = ['Red', 'Blue', 'Black', 'Orange']
    if request.method == "POST":
        from defs import allowed_file, mkDirs
        tName = request.form.get("testName")
        mkDirs(app.config['UPLOAD_FOLDER'], tName)
        runMTH=request.form['options']
        ups=[]
        for f in request.files.getlist('myFile'):
            if(allowed_file(f.filename)):
                filename = secure_filename(f.filename)
                ups.append(os.path.join(app.config['UPLOAD_FOLDER'], tName, filename))
                f.save(os.path.join(app.config['UPLOAD_FOLDER'], tName, filename))
        return render_template('runRLR.html', msg='Upload completed. ' + ", ".join(ups), dFname=os.path.join(app.config['UPLOAD_FOLDER'], tName, "EventIds.csv").replace("\\","/"))

    else:
        return render_template('runRLR.html')

#https://stackoverflow.com/questions/17681762/unable-to-retrieve-files-from-send-from-directory-in-flask
@app.route('/downloads/<path:filename>', methods=['GET', 'POST'])
def download(filename):
    uploads = os.path.join(app.config['UPLOAD_FOLDER'], "Test1")
    return send_from_directory(directory='', filename=filename)

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
    app.run(host='0.0.0.0', port = 5005, debug=True)