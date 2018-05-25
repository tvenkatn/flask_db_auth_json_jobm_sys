from flask import Blueprint, render_template, jsonify, request
import os, csv, json, datetime
from flask_login import login_required

mdv = Blueprint('mdv',__name__,template_folder='templates')

vulnToolRelPath = os.path.join(os.getcwd(), 'RMSTools/Vulnerability/latest')

@mdv.route('/')
def index():
    return 'Welcome to mdv blueprints'

@mdv.route('/vulnValidationRun', methods=["GET", "POST"])
def vulnValidationRun():
    with open('data/serList.csv', 'r') as f:
        serList = [line.strip() for line in f]
    if request.method == "POST" and 'server' in request.form and request.form['action'] == 'getDb':
        from bin.defs import getVulnDbs
        thisSer = request.form.get("server")
        vulns = getVulnDbs(thisSer)
        return render_template('vulnValidationInputs.html', serList=serList, selVuln=vulns, selSer = thisSer)
    elif request.method == "POST" and 'server' in request.form and request.form['action'] == 'runVulnValidation':
        from mod_tools_mdv.bin.defs import runRinBack_VulnValid
        dtNow = datetime.datetime.now().strftime("%Y%m%d_%Hh%Mm%Ss")
        vConfig = {
                # "currentPath": os.getcwd(),
                "DBserver": request.form.get("server"),
                "VULNDB": request.form.get("thisVuln"),
                "Perils": request.form.getlist("thisPeril"),
                "Countries": request.form.getlist("thisCountry"),
                "NGGeography": {
                    "db": "RMS_NGGeography",
                    "server": "ca1mdtools01",
                    "userid": "sa",
                    "password": "Rmsuser!"
                    }
                }
        with open(os.path.join(vulnToolRelPath, 'config.json'), 'w', encoding="utf-8", newline='\n') as fp:
            json.dump(vConfig, fp, indent=4, sort_keys=True, ensure_ascii=False)

        # execute script
        runRinBack_VulnValid(vulnToolRelPath, dtNow)

        return jsonify(vConfig)
    return render_template('vulnValidationInputs.html', serList=serList)

@mdv.route('/returnPerilModels', methods=["GET", "POST"])
def returnPerilModels():
    """curl --data "thisSer=ca1mdtools01" --data "thisDb=RMS_VULNERABILITY_EUFL_official" http://10.100.190.137:5005/mdv/returnPerilModels"""
    from mod_tools_mdv.bin.defs import getCountryPerils
    if request.method == "POST":
        perilModels = getCountryPerils(request.form['thisSer'], request.form['thisDb'])
    else:
        perilModels = getCountryPerils('ca1mdtools01', 'RMS_VULNERABILITY_EUFL_official')
    return jsonify(perilModels)

@mdv.route('/testAction1', methods=["GET", "POST"])
def testAction1():
    return "I am here"