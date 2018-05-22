from flask import Blueprint, render_template, jsonify, request
import os, csv, json
from flask_login import login_required

mdv = Blueprint('mdv',__name__,template_folder='templates')

@mdv.route('/')
def index():
    return 'Welcome to mdv blueprints'

@mdv.route('/vulnValidationRun', methods=["GET", "POST"])
def vulnValidationRun():
    with open('data/serList.csv', 'r') as f:
        serList = [line.rstrip() for line in f]
    if request.method == "POST" and 'server' in request.form and request.form['action'] == 'getDb':
        from bin.defs import getVulnDbs
        thisSer = request.form.get("server")
        vulns = getVulnDbs(thisSer)
        return render_template('vulnValidationInputs.html', serList=serList, selVuln=vulns, selSer = thisSer)
    elif request.method == "POST" and 'server' in request.form and request.form['action'] == 'runVulnValidation':
        vConfig = {
                "server": request.form.get("server"),
                "vuln": request.form.get("thisVuln"),
                "peril": request.form.getlist("thisPeril"),
                "country": request.form.getlist("thisCountry")
            }
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