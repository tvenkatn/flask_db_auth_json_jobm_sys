from flask import Blueprint, render_template, jsonify, request

e2e = Blueprint('e2e',__name__,template_folder='templates')

@e2e.route('/')
def inedx():
    return 'Welcome to E2E blueprints'

#region autocreate inputs test
@e2e.route('/eqhdauto', methods=['GET', 'POST'])
def eqhdauto():
    thisReq = {}
    if request.method=='POST':
        f = request.form
        for key in f.keys():
            for value in f.getlist(key):
                print(key, ":", value)
                thisReq[key] = value
        # return 'This is a post request' + ' ' + str(request.form.__len__())
        return jsonify(thisReq)
    return render_template('eqhd.html')

@e2e.route('/eqhdConfig')
def eqhdConfig():
    cg = {
            "EDM": "RMS_EDM",
            "Portid": 2,
            "NGDLMPath": "D:/main/NGDLMData"
        }
    return jsonify(cg)

#endregion

