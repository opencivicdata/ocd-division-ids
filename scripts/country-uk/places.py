import csv
import glob
import re
import sys

# Note: This requires the UK Ordnance Survey OS Open Names dataset in CSV,
# which is free and liberally licensed, but requires agreeing to a license and
# downloading via an emailed link from their site.
# https://www.ordnancesurvey.co.uk/opendatadownload/products.html#OPNAME

data_dir = 'opname_csv_gb/DATA'

ocd_base = 'ocd-division/country:uk'

def make_id(type_id):
    replacements = ['\'', ' &', ',', ' Assembly Const',
                    ' P Const', ' GL', ' ED', ' CP', '_CONST', '(', ')', ]
    for replacement in replacements:
        type_id = type_id.replace(replacement, '')

    type_id = type_id.lower()
    type_id = re.sub('\.? ', '_', type_id)
    type_id = re.sub('[^\w0-9~_.-]', '~', type_id, re.UNICODE)
    return type_id


def make_name(const_name):
    replacements = [' Assembly Const',
                    ' P Const', ' Const', ' GL', ' ED', ' CP']
    for replacement in replacements:
        const_name = const_name.replace(replacement, '')
    return const_name


def write_csv(filename, csv_columns, dict_data):
    with open(filename, 'w') as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=csv_columns)
        writer.writeheader()
        for data in dict_data:
            writer.writerow(data)


juris_type_mapping = {
    'UnitaryAuthority' : 'uta',
    'County' : 'cty',
    'MetropolitanDistrict' : 'mtd',
    'GreaterLondonAuthority': 'gla'
}

rows = []
seen_ids = []
for filename in glob.glob('{}/*.csv'.format(data_dir)):
    print(filename)
    with open(filename, 'r') as csvfile:
        reader = csv.reader(csvfile)
        for record in reader:
            if record[6] == 'populatedPlace':
                row = {}

                if record[26]:
                    jursidction_type = record[26]
                elif record[23]:
                    jursidction_type = record[23]

                jurisdiction_type = jursidction_type.replace('http://data.ordnancesurvey.co.uk/ontology/admingeo/', '')
                if jurisdiction_type in juris_type_mapping:
                    parent_type = juris_type_mapping[jurisdiction_type]

                    # parent id moves depending on the jursidiction type
                    if record[24]:
                        parent_id = record[24]
                    else:
                        parent_id = record[21]

                    parent_id = make_id(parent_id)

                    local_type = make_id(record[7])
                    local_type = local_type.replace('other_settlement', 'settlement')
                    local_id = make_id(record[2])

                    row['id'] = '{}/{}:{}/{}:{}'.format(
                        ocd_base,
                        parent_type,
                        parent_id,
                        local_type,
                        local_id
                    )

                    row['name'] = record[2]
                    row['dbpedia'] = record[32]
                    row['geonames'] = record[33]

                    if row['id'] not in seen_ids:
                        rows.append(row)
                        seen_ids.append(row['id'])
                else:
                    print(record)
                    print (jurisdiction_type)
                    sys.exit("Unknown type map")

csv_filename = 'identifiers/country-uk/places.csv'
write_csv(csv_filename, rows[0].keys(), rows)