from flask import Blueprint, render_template, jsonify, request
import os, csv, json
from flask_login import login_required

getLogs = Blueprint('getLogs',__name__,template_folder='templates', static_folder='static')

HDReg_wd = r'\\cawd16744\HD_testRegression'
HDReg_repFormat = "allReports.csv$"
JPEQ_N_PATH = r'N:\ModelCertification\Projects\_2018\HD18_JPEQ\TestExecution'

@getLogs.route('/')
def index():
    return 'Welcome to logs blueprints'

#region autocreate inputs test
@getLogs.route('/getHDRLog', methods=['POST'])
def getHDRLog():
    """curl -X POST -F "ser=20180413_14h31m09s" "http://10.100.190.137:5005/logs/getHDRLog"""
    if request.method == "POST":
        reqData = request.form['ser']
    else:
        reqData = "20180413_14h31m09s"
    thisfname = os.path.join(HDReg_wd,"reports",str(reqData) + "_allReports.csv")
    csvfile = open(thisfname, 'r')
    # TODO: get this log file from actual HD regression
    from mod_logs.bin.defs import getCsvNCol
    lenCsv = getCsvNCol(thisfname)

    if lenCsv == 4:
        fieldnames = ("a", "b", "c", "d")
    else:
        fieldnames = ("a", "iter", "runtype", "b", "c", "d")
    reader = csv.DictReader(csvfile, fieldnames)
    allRecords = []
    record = {}
    for row in reader:
        record['a'] = os.path.basename(os.path.dirname(os.path.dirname(row['a'])))
        if len(row) == 4:
            record['iter'] = "It00"
            record['runtype'] = "UNK"
        else:
            record['iter'] = row['iter']
            record['runtype'] = row['runtype']
        record['b'] = row['b']
        record['c'] = row['c']
        record['d'] = row['d']
        record['testPath'] = os.path.join(HDReg_wd, *row['a'].split('/')[3:-2])
        if record['a'][0:3] == 'HAZ':
            dName = 'Hazard'
        elif record['a'][0:3] == 'VUL':
            dName = 'Vulnerability'
        else:
            dName = 'Loss Validations'
        record['NPath'] = os.path.join(JPEQ_N_PATH, dName, record['a'])
        allRecords.append(json.dumps(record))
    return jsonify(allRecords)

@getLogs.route('/getLogsList')
@login_required
def eqhdConfig():
    from mod_logs.bin.defs import getAllFiles
    allFiles = getAllFiles(HDReg_wd, HDReg_repFormat)
    allFilesDates = [x.split('_a')[0] for x in allFiles]
    allFilesDates.sort(reverse = True)
    return render_template('hdr_logSelect.html', selLogs = allFilesDates)
    # return jsonify(allFiles)

#endregion

