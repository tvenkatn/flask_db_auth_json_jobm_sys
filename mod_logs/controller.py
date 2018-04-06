from flask import Blueprint, render_template, jsonify, request
import os, csv, json

getLogs = Blueprint('getLogs',__name__,template_folder='templates')

HDReg_wd = r'\\cawd16744\HD_testRegression'
HDReg_repFormat = "allReports.csv$"

@getLogs.route('/')
def index():
    return 'Welcome to logs blueprints'

#region autocreate inputs test
@getLogs.route('/getHDRLog', methods=['POST'])
def getHDRLog():
    if request.method == "POST":
        reqData = request.form['ser']
    else:
        reqData = "20170629_14h06m26s"
    fn_ = os.path.join(HDReg_wd,"reports",str(reqData) + "_allReports.csv")
    csvfile = open(fn_, 'r')
    # TODO: get this log file from actual HD regression
    fieldnames = ("a", "b", "c", "d");
    reader = csv.DictReader(csvfile, fieldnames)
    allRecords = []
    record = {}
    for row in reader:
        record['a'] = os.path.basename(os.path.dirname(os.path.dirname(row['a'])))
        record['b'] = row['b']
        record['c'] = row['c']
        record['d'] = row['d']
        allRecords.append(json.dumps(record))
    return jsonify(allRecords)


@getLogs.route('/getLogsList')
def eqhdConfig():
    from mod_logs.bin.defs import getAllFiles
    allFiles = getAllFiles(HDReg_wd, HDReg_repFormat)
    allFilesDates = [x.split('_a')[0] for x in allFiles]
    allFilesDates.sort(reverse = True)
    return render_template('hdr_logSelect.html', selLogs = allFilesDates)
    # return jsonify(allFiles)

#endregion

