import os
from flask import Flask, url_for, redirect, render_template, request, flash, jsonify, json, send_from_directory
from flask_sqlalchemy import SQLAlchemy
import datetime
import psycopg2
import subprocess
import csv
import json
from werkzeug import generate_password_hash, check_password_hash, secure_filename
from flask_wtf import FlaskForm
from wtforms import PasswordField, StringField, BooleanField, SubmitField
from wtforms.validators import DataRequired, ValidationError, Email, EqualTo
from flask_login import LoginManager, login_user, login_required, logout_user, UserMixin, current_user
from celery import Celery
from flask_socketio import SocketIO, emit
import time

# import eventlet
# eventlet.monkey_patch()

# to turn on Celery, run
# celery worker -A app.celery --loglevel=info
# in a separate command window within the same venv as the app

UPLOAD_FOLDER = './rFiles/rlr/'
LOG_FOLDER = './logs/'
e2eLogFolder = r'D:\Srinivas\mytools\EQ_E2E'
GEOHAZ_TOOLPATH = r'D:\Srinivas\tools\ModelDev_TFS\ModelDataValidation\Geohaz\latest'
# e2eLogFolder = r'D:\Srinivas\work\20180105_flask_db_auth_json\rFiles\hdr'

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI']='postgresql://postgres:welcome@localhost/flaskApp1'
db=SQLAlchemy(app)
app.secret_key = 'CatchMe, if yOU Ca nn~!'

from mod_E2E.controller import e2e
from mod_logs.controller import getLogs
from mod_tools_mdv.controller import mdv
app.register_blueprint(e2e, url_prefix = '/e2e')
app.register_blueprint(getLogs, url_prefix = '/logs')
app.register_blueprint(mdv, url_prefix = '/mdv')

login = LoginManager(app)
login.login_view = 'login' # tells where to redirect if @login_required is not met!
app.config['TESTING'] = False
ENABLE_REGISTRATIONS = False

app.config['LOG_FOLDER'] = LOG_FOLDER
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['CELERY_BROKER_URL'] = 'redis://localhost:6379/0'
app.config['CELERY_RESULT_BACKEND'] = 'redis://localhost:6379/0'
app.config['SOCKETIO_REDIS_URL'] = 'redis://localhost:6379/0'
# socketio = SocketIO(app, async_mode='eventlet', message_queue=app.config['SOCKETIO_REDIS_URL'])
socketio = SocketIO(app)
celery = Celery(app.name, broker=app.config['CELERY_BROKER_URL'], backend=app.config['CELERY_RESULT_BACKEND'])
celery.conf.update(app.config)



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
        
class User(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(64), index=True, unique=True)
    email = db.Column(db.String(120), index=True, unique=True)
    password_hash = db.Column(db.String(128))

    def __repr__(self):
        return '<User {}>'.format(self.username)

    def getUName(self):
        return self.username

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

@login.user_loader
def load_user(id):
    return User.query.get(int(id))

class RunRTasks(db.Model):
    __tablename__="runRTasks"
    id=db.Column(db.Integer, primary_key=True)
    color_= db.Column(db.String(20), unique=False)
    initTime = db.Column(db.DateTime, default=datetime.datetime.now)
    status_ = db.Column(db.String(120), unique=False, default="Pending")
    taskId_ = db.Column(db.String(120), unique=True)

    def __init__(self, color_, status_, taskId_):
        self.color_=color_
        self.status_=status_
        self.taskId_ = taskId_

# for geohazard validation tool logging
class RunGeohazValidTasks(db.Model):
    __tablename__="runGeohazValidTasks"
    id=db.Column(db.Integer, primary_key=True)
    server_= db.Column(db.String(40), unique=False)
    initTime = db.Column(db.DateTime, default=datetime.datetime.now)
    db_ = db.Column(db.String(120), unique=False)
    status_ = db.Column(db.String(120), unique=False, default="Pending")
    taskId_ = db.Column(db.String(120), unique=True)
    reportName_ = db.Column(db.String(120), unique=True)

    def __init__(self, server_, db_, status_, taskId_, reportName_):
        self.server_ = server_
        self.db_ = db_
        self.status_ = status_
        self.taskId_ = taskId_
        self.reportName_ = reportName_

## form templates
# class SignupForm(Form):
#     firstname = TextField("First name",  [validators.Required("Please enter your first name.")])
#     lastname = TextField("Last name",  [validators.Required("Please enter your last name.")])
#     email = TextField("Email",  [validators.Required("Please enter your email address."), validators.Email("Please enter your email address.")])
#     password = PasswordField('Password', [validators.Required("Please enter a password.")])
#     submit = SubmitField("Create account")
#
#     def __init__(self, *args, **kwargs):
#         Form.__init__(self, *args, **kwargs)
#
#     def validate(self):
#         if not Form.validate(self):
#             return False
#         user = db.session.query(User).filter_by(email = self.email.data.lower()).first()
#         if user:
#             self.email.errors.append("That email is already taken")
#             return False
#         else:
#             return True

class RegistrationForm(FlaskForm):
    username = StringField('Username', validators=[DataRequired()])
    email = StringField('Email', validators=[DataRequired(), Email()])
    password = PasswordField('Password', validators=[DataRequired()])
    password2 = PasswordField(
        'Repeat Password', validators=[DataRequired(), EqualTo('password')])
    submit = SubmitField('Register')

    def validate_username(self, username):
        user = User.query.filter_by(username=username.data).first()
        if user is not None:
            raise ValidationError('Please use a different username.')

    def validate_email(self, email):
        user = User.query.filter_by(email=email.data).first()
        if user is not None:
            raise ValidationError('Please use a different email address.')

class LoginForm(FlaskForm):
    username = StringField('Username', validators=[DataRequired()])
    password = PasswordField('Password', validators=[DataRequired()])
    remember_me = BooleanField('Remember Me')
    submit = SubmitField('Sign In')

# @app.route('/signup', methods=['GET', 'POST'])
# def signup():
#     if 'email' in session:
#         return redirect(url_for('profile'))
#     form = SignupForm()
#     if request.method == 'POST':
#         if form.validate() == False:
#             return render_template('signup.html', form=form)
#         else:
#             newuser = User(form.firstname.data, form.lastname.data, form.email.data, form.password.data)
#             db.session.add(newuser)
#             db.session.commit()
#             session['email'] = newuser.email
#             return redirect(url_for('profile'))
#
#     elif request.method == 'GET':
#         db.create_all()
#         return render_template('signup.html', form=form)

@app.route('/login', methods=['GET', 'POST'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for('main'))
    form = LoginForm()
    if form.validate_on_submit():
        user = User.query.filter_by(username=form.username.data).first()
        if user is None or not user.check_password(form.password.data):
            flash('Invalid username or password')
            return redirect(url_for('login'))
        login_user(user, remember=form.remember_me.data)
        return redirect(url_for('main'))
    return render_template('login.html', title='Sign In', form=form, register = ENABLE_REGISTRATIONS)

@app.route('/register', methods=['GET', 'POST'])
def register():
    db.create_all()
    if current_user.is_authenticated:
        return redirect(url_for('main'))
    form = RegistrationForm()
    if form.validate_on_submit():
        user = User(username=form.username.data, email=form.email.data)
        user.set_password(form.password.data)
        db.session.add(user)
        db.session.commit()
        flash('Congratulations, you are now a registered user!')
        return redirect(url_for('main'))
    return render_template('register.html', title='Register', form=form)
#
# @app.route('/profile')
# def profile():
#     if 'email' not in session:
#         return redirect(url_for('signup'))
#     user = User.query.filter_by(email = session['email']).first()
#     if user is None:
#         return redirect(url_for('signup'))
#     else:
#         return render_template('profile.html')

# @app.route('/signout')
# def signout():
#     if 'email' not in session:
#         return redirect(url_for('signup'))
#     session.pop('email', None)
#     return redirect(url_for('signup'))

@app.route('/logout')
def logout():
    logout_user()
    return redirect(url_for('main'))

@app.route("/", methods=["GET", "POST"])
def main():
    if current_user.is_authenticated:
        return render_template('welcome.html', name_=current_user.username)
    else:
        return render_template('welcome.html', loginReq=True)

@app.route('/HH<name>')
def hello_name(name):
    return 'Hello %s!' % name

#http://127.0.0.1:5000/HHsri
#HH is case sensitive. URLs should be case sensitive!!
#https://stackoverflow.com/questions/28801707/case-insensitive-routing-in-flask

@celery.task
def runRinBack(thisCol):
    subprocess.call(["cmd", "/c", "Rscript", "D:/Srinivas/work/20180105_flask_db_auth_json/rFiles/createFiles.r",""""%s""" % thisCol])

def runRinBackNC(thisCol):
    subprocess.call(["cmd", "/c", "Rscript", "D:/Srinivas/work/20180105_flask_db_auth_json/rFiles/createFiles.r",""""%s""" % thisCol])
    return("done")


@app.route('/ddtest', methods=["GET", "POST"])
@login_required
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
@login_required
def defTest():
    from bin.defs import getNames
    colours = ['Red', 'Blue', 'Black', 'Orange']
#    colours = getColors()
    colours = getNames()
    if request.method == "POST" and 'thisColor' in request.form:
#        return "the selected color is %s" % request.form.get("thisColor")
        return render_template('allUsers.html', colours=colours, selColor = request.form.get("thisColor"))
    else:
        return render_template('allUsers.html', colours=colours)

@app.route('/getVulns', methods=["GET", "POST"])
@login_required
def getVulns():
    # serList = ["ca-md1-02","ca1mdrlcsint02","ca1mdmcert30","ca1mdtools01","ca1mdnaeq18"];
    with open('data/serList.csv', 'r') as f:
        serList = [line.rstrip() for line in f]
    if request.method == "POST" and 'server' in request.form:
        from bin.defs import getVulnDbs
        vulns = getVulnDbs(request.form.get("server"))
        # return "the selected server is %s" % ser
        return render_template('allVulns.html', serList=serList, selVuln=vulns)
    else:
        return render_template('allVulns.html', serList=serList)

@app.route('/runR', methods=["GET", "POST"])
@login_required
def runR():
    colours = ['Red', 'Blue', 'Black', 'Orange']
    db.create_all()
    if request.method == "POST" and 'thisColor' in request.form:
#        return "the selected color is %s" % request.form.get("thisColor")
        tc = request.form.get("thisColor")
        task = runRinBack.delay(tc)
        runRTasks=RunRTasks(tc, "Pending", task.id)
        db.session.add(runRTasks)
        db.session.commit()
        return render_template('allUsers.html', colours=colours, selColor = request.form.get("thisColor") + ". Task ID: " + task.id + ". Location: " + url_for('taskstatus',
                                                  task_id=task.id) + ". State: " + runRinBack.AsyncResult(task.id).state, statusPageLink=True)
    else:
        return render_template('allUsers.html', colours=colours)

@app.route('/status/<task_id>')
@login_required
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

@app.route('/runRStatus')
@login_required
def runRStatus():
    tasks = db.session.query(RunRTasks)
    tid = {}
    for task in tasks:
        runStat = str(runRinBack.AsyncResult(task.taskId_).state)
        tid[task.taskId_] = (runStat,task.id,task.color_, str(task.initTime))
    # return jsonify(tid)
    # tid = []
    # for task in tasks:
    #     tid.append((task.id, task.color_, task.initTime, runRinBack.AsyncResult(task.taskId_).state))
    # return type(list(tid.values()))
    return render_template('runRStatus.html', tasks_=list(tid.values()))
    # return render_template(runRStatus, tasks_=list(tid.values()))

@socketio.on('my event', namespace='/test')
def test_message(message):
    i = 10
    k=0
    time.sleep(3)
    emit('my response', {'data': 'Backend saw "' + message['data'] + '" from the frontend. Time at ' + time.strftime("%H:%M:%S")})
    # for k in range(0,i):
    #     emit('my response',
    #          {'data': 'Backend saw "' + message['data'] + '" from the frontend. Time at ' + time.strftime("%H:%M:%S")})
    #     time.sleep(5)
    # while k < i:
    #     emit('my response', {'data': 'Backend saw "' + message['data'] + '" from the frontend. Time at ' + time.strftime("%H:%M:%S")})
    #     k+=1
    #     time.sleep(5)

@app.route('/getHDRLog')
@app.route('/getHDRLog/<path:fname>')
def getHDRLog(fname_= r'D:\Srinivas\work\20180105_flask_db_auth_json\rFiles\hdr\20170629_14h06m26s_allReports.csv'):
    fn_= fname_
    csvfile = open(fn_, 'r')
    # TODO: get this log file from actual HD regression
    fieldnames = ("a", "b", "c", "d");
    reader = csv.DictReader(csvfile, fieldnames)
    allRecords = []
    record = {}
    for row in reader:
        record['a'] = row['a']
        record['b'] = row['b']
        record['c'] = row['c']
        record['d'] = row['d']
        allRecords.append(json.dumps(record))
    return jsonify(allRecords)

@app.route('/showHDRLog')
@login_required
def showHDRLog():
    return render_template('showHDRLogs.html')

@app.route('/getE2ELog')
@app.route('/getE2ELog/<path:fname_>')
def getE2ELog(fname_ = r'D:\Srinivas\work\20180105_flask_db_auth_json\rFiles\hdr\JPEQ_Debug38_FFMismatch_test.log'):
    fn_= fname_
    if os.path.splitext(fname_)[1]=="":
        fn_= fn_ + ".log"
    if os.path.dirname(fn_)=="":
        fn_=os.path.join(e2eLogFolder, fn_)
    text_file = open(fn_, "r")
    lines = [line for line in text_file.readlines()]
    text_file.close()
    return jsonify(lines)

@app.route('/showE2ELog')
@app.route('/showE2ELog/<path:fname_>')
@login_required
def showE2ELog(fname_):
    return render_template('showE2ELogs.html')

@app.route('/getTime')
def getTime():
    return render_template('fromSocket.html')

@app.route('/rlrunner', methods=["GET", "POST"])
@login_required
def rlrunner():
    colours = ['Red', 'Blue', 'Black', 'Orange']
    if request.method == "POST" and 'thisColor' in request.form:
#        return "the selected color is %s" % request.form.get("thisColor")
        R = subprocess.call(["cmd", "/c", "cd", "D:/main/test", "\&\&", "Rscript","N:/APPLICS/EngTools/R_packages/EDS_Runner/EDS_Runner_JPEQ.R", """%s""" % "D:/main/lib", """%s""" % "runMTH=1", """%s""" % "calcAAL=0", """%s""" % "EQ"])
        return render_template('allUsers.html', colours=colours, selColor = request.form.get("thisColor"))
    else:
        return render_template('allUsers.html', colours=colours)    

@app.route('/rlr', methods=["GET", "POST"])
@login_required
def rlr():
    db.create_all()
    if request.method == "POST":
        from bin.defs import allowed_file, mkDirs
        tName = request.form.get("testName")
        mkDirs(app.config['UPLOAD_FOLDER'], tName)
        runMTH=request.form['options']
        ups=[]
        for f in request.files.getlist('file'):
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

@celery.task
def runGeohazValidBack(toolPath, dbName, dbSer, repName):
    a = ["cmd", "/c", "Rscript", os.path.join(toolPath,"Main.r"), """\"%s\" \"%s\" \"%s\" \"%s\" \"%s\"""" % (dbName, dbSer, "sa", "Rmsuser!", repName)]
    subprocess.call(" ".join(a))

@app.route('/runGeohazValid', methods=["GET", "POST"])
@login_required
def runGeohazValid():
    db.create_all()
    with open('data/serList.csv', 'r') as f:
        serList = [line.rstrip() for line in f]
    if request.method == "POST" and 'server' in request.form:
        from bin.defs import getGeohazDbs
        thisSer = request.form.get("server")
        geohazs = getGeohazDbs(thisSer)
        return render_template('runGeohazValidation.html', serList=serList, selGeohazs=geohazs, thisSer=thisSer)
    elif 'myServer' in request.form:
        ghazDb = request.form.get("thisGeohaz")
        thisSer = request.form.get("myServer")
        reportName = datetime.datetime.now().strftime("%Y%m%d_%Hh%Mm%Ss")
        # return jsonify([(GEOHAZ_TOOLPATH), str(ghazDb), str(thisSer), str(reportName)])
        task = runGeohazValidBack.delay(str(GEOHAZ_TOOLPATH), str(ghazDb), str(thisSer), str(reportName))
        runRGeoHaz = RunGeohazValidTasks(thisSer, ghazDb, "Pending", task.id, reportName)
        db.session.add(runRGeoHaz)
        db.session.commit()
        return redirect(url_for('getGVStatus'))
    else:
        return render_template('runGeohazValidation.html', serList=serList)

@app.route('/getGVStatus', methods=["GET", "POST"])
@login_required
def getGVStatus():
    tasks = db.session.query(RunGeohazValidTasks)
    tid = {}
    numShow = 5
    if request.method == "POST":
        numShow = int(request.form.get("thisGeohaz"))
    for task in tasks[-1*int(numShow):]:
        runStat = str(runGeohazValidBack.AsyncResult(task.taskId_).state)
        if runStat == "SUCCESS":
            tsk = db.session.query(RunGeohazValidTasks).filter_by(taskId_=task.taskId_).first()
            tsk.status_ = "Success"
            db.session.commit()
        elif runStat == "FAILURE":
            tsk = db.session.query(RunGeohazValidTasks).filter_by(taskId_=task.taskId_).first()
            tsk.status_ = "Fail"
            db.session.commit()
        qr = db.session.query(RunGeohazValidTasks).filter_by(taskId_=task.taskId_).first()
        runStatNow = qr.status_
        repLink = task.reportName_
        tid[task.taskId_] = (task.id, task.server_, task.db_, str(task.initTime), runStatNow, repLink)
    return render_template('getGeohazValidationStatus.html', tasks_=list(tid.values()))

@app.route('/getGVReport/<rep_name>')
@login_required
def getGVReport(rep_name):
    return send_from_directory(directory=os.path.join(str(GEOHAZ_TOOLPATH),'log'), filename="Report_"+rep_name+".html")
    # return render_template(os.path.join(str(GEOHAZ_TOOLPATH),'log',"Report_"+rep_name+".html"))

#region plotEDM
@app.route('/leaf')
def leaf():
    return render_template("leafMaps.html")

@app.route('/viewEDM', methods=["GET", "POST"])
def viewEDM():
    db.create_all()
    with open('data/serList.csv', 'r') as f:
        serList = [line.rstrip() for line in f]
    if request.method == "POST" and 'server' in request.form:
        from bin.defs import getEDMDbs
        thisSer = request.form.get("server")
        if len(thisSer) ==0:
            flash(u'Please provide a server', 'danger')
            return render_template('viewEDM.html', serList=serList)
        else:
            geohazs = getEDMDbs(thisSer)
            return render_template('viewEDM.html', serList=serList, selGeohazs=geohazs, thisSer=thisSer)

    elif 'myServer' in request.form:
        ghazDb = request.form.get("thisGeohaz")
        thisSer = request.form.get("myServer")
        Port = request.form.get("portfolios")
        thisPort = Port.split('_')[0]
        with open(os.path.join(app.config['LOG_FOLDER'], 'leafEDM.txt'), 'a') as myFile:
            myFile.write('\nAccessed on ' + str(datetime.datetime.now()) + ' by ' + request.remote_addr)
            myFile.write('\n\tServer: ' + thisSer + '; EDM: ' + ghazDb+ '; Port: ' + thisPort)
        return redirect(url_for('leaf_EDM', ser = thisSer, edm = ghazDb, port = Port))
    else:
        return render_template('viewEDM.html', serList=serList)

@app.route('/getEDMPorts', methods=['POST'])
def getEDMPorts():
    edmSer = request.form['ser']
    edm = request.form['edm']
    from bin.defs import getEDMPorts
    return jsonify(getEDMPorts(edmSer, edm))

@app.route('/leaf_EDM')
def leaf_EDM():
    ser = request.args.get('ser')
    edm = request.args.get('edm')
    port = request.args.get('port')
    return render_template("leafMaps_EDM.html", ser = ser, edm = edm, port = port)

@app.route('/getLocData')
def getLocData():
    # TODO: get these lat-longs as dict from EDM
    reader = [
        {
            "lat": 37.250615,
            "lon": -122.13778,
            "title": "Point1"
        },
        {
            "lat": 37.550615,
            "lon": -122.069778,
            "title": "Point2"
        }
    ]
    allRecords = []
    record = {}
    for row in reader:
        record['lat'] = row['lat']
        record['lon'] = row['lon']
        record['title'] = row['title']
        allRecords.append(json.dumps(record))
    return jsonify(allRecords)

@app.route('/getPortLocs', methods=['GET', 'POST'])
def getPortLocs():
    from bin.defs import LocsPorts
    ser = request.form['ser']
    edm = request.form['edm']
    port = int(request.form['port'])
    allRecords = LocsPorts(ser, edm, port)
    return jsonify(allRecords)

#endregion

if __name__ == '__main__':
    # app.run(host='0.0.0.0', port = 5005, debug=True)
    socketio.run(app, host='0.0.0.0', port = 5005, debug=True)