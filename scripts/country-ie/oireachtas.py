import requests
import json
import csv
import re

# fetch the lower / upper consitutuencies of the Oreichtas from the IE api
# https://api.oireachtas.ie/
# /houses to get the houses (sessions in U.S. terminology)
# /constituencies to get the divisions
# the Irish Seanad apointments come from some unusual sources, maybe these should be ocd-jurisdictions?

def make_id(type_id):
    replacements = []
    for replacement in replacements:
        type_id = type_id.replace(replacement, '')

    type_id = type_id.lower()
    type_id = re.sub('\.? ', '_', type_id)
    type_id = re.sub('[^\w0-9~_.-]', '~', type_id, re.UNICODE)
    return type_id

def write_csv(filename, csv_columns, dict_data):
    with open(filename, 'w') as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=csv_columns)
        writer.writeheader()
        for data in dict_data:
            writer.writerow(data)


def get_most_recent_houses():
    latest = {}

    url = 'https://api.oireachtas.ie/v1/houses'
    req = requests.get(url)
    res = json.loads(req.content)
    for session in res['results']:
        if session['house']['dateRange']['end'] is None:
            latest[session['house']['chamberCode']] = session['house']['houseNo']

    return latest

ocd_base = 'ocd-division/country:ie'

rows = []

sessions = get_most_recent_houses()

for house in ['dail','seanad']:
    url = 'https://api.oireachtas.ie/v1/constituencies?chamber={}&house_no={}&limit=500'.format(house, sessions[house])
    req = requests.get(url)
    res = json.loads(req.content)
    for district in res['results']['house']['constituenciesOrPanels']:
        row = {}
        name = district['constituencyOrPanel']['showAs']
        local_id = make_id(name)

        # lower / dail
        if district['constituencyOrPanel']['representType'] == 'constituency':
            row['id'] = '{}/constituency:{}'.format(ocd_base, local_id)
        elif district['constituencyOrPanel']['representType'] == 'panel':
            row['id'] = '{}/panel:{}'.format(ocd_base, local_id)

        row['name'] = name
        rows.append(row)

csv_filename = 'identifiers/country-ie/oireachtas.csv'
write_csv(csv_filename, rows[0].keys(), rows)