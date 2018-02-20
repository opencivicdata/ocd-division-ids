import shapefile
import csv
import re

# Note: This requires the UK Ordnance Survey Boundaries dataset,
# which is free and liberally licensed, but requires agreeing to a license and
# downloading via an emailed link from their site.
# https://www.ordnancesurvey.co.uk/opendatadownload/products.html#BDLINE


def read_records(filename):
    sf = shapefile.Reader(filename)
    records = sf.records()
    for record in records:
        yield record

def debug_print(filename):
    for record in read_records(filename):
        print(record)

def get_overview(filename):
    sf = shapefile.Reader(filename)
    return sf.fields

def write_csv(filename,csv_columns, dict_data):
    with open(filename, 'w') as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=csv_columns)
        writer.writeheader()
        for data in dict_data:
            writer.writerow(data)

def make_id(type_id):
    replacements = ['&','(',')',',',' Assembly Const', ' P Const', ' GL', ' ED', ' CP']
    for replacement in replacements:
        type_id = type_id.replace(replacement, '')

    type_id = type_id.lower()
    type_id = re.sub('\.? ', '_', type_id)
    type_id = re.sub('[^\w0-9~_.-]', '~', type_id, re.UNICODE)
    return type_id

def make_name(const_name):
    replacements = [' Assembly Const', ' P Const', ' Const', ' GL',' ED', ' CP']
    for replacement in replacements:
        const_name = const_name.replace(replacement, '')
    return const_name


def build_csv_file(data_dir, shape_group_name, refine_locals=False):

    rows = []
    shape_file = '{}/{}'.format(data_dir, shape_group_name)
    for record in read_records(shape_file):
        if record[12] == 'FILLER AREA':
            continue

        row = {}

        # in some data files, the record[3] field DESCRIPTIO
        # works fine, in others it would produce dupes
        if refine_locals:
            local_id = make_id(record[0])
        else:
            local_id = record[3].replace('_CONST','').lower()

        division_type = record[1].lower()
        row['ocd'] = '{}/{}/{}'.format(ocd_base, division_type, local_id)
        row['name'] = make_name(record[0])
        row['ordnance_id'] = record[8]
        rows.append(row)

    group_name = shape_group_name.replace('_region', '')
    csv_filename = 'identifiers/country-uk/{}.csv'.format(group_name)
    write_csv(csv_filename, rows[0].keys(), rows)



ocd_base = 'ocd-division/country:uk'

data_dir = '/Users/showerst/Downloads/bdline_essh_gb/Data/GB'


# To see what these files contain,
# debug_print('{}/{}'.format(data_dir, 'westminster_const_region'))

build_csv_file(data_dir, 'westminster_const_region')
build_csv_file(data_dir, 'scotland_and_wales_const_region', True)
build_csv_file(data_dir, 'greater_london_const_region', True)
build_csv_file(data_dir, 'county_region')
build_csv_file(data_dir, 'unitary_electoral_division_region', True)
build_csv_file(data_dir, 'parish_region', True)
build_csv_file(data_dir, 'district_borough_unitary_ward_region', True)
build_csv_file(data_dir, 'district_borough_unitary_region', True)
