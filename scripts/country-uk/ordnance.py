import shapefile
import csv
import re
import collections

# Note: This requires the UK Ordnance Survey Electoral Boundaries dataset,
# which is free and liberally licensed, but requires agreeing to a license and
# downloading via an emailed link from their site.
# https://www.ordnancesurvey.co.uk/opendatadownload/products.html#BDLINE

# it also assumes pyshp -- pip3 install pyshp

# Change this to your download location
data_dir = 'bdline_essh_gb/Data'
uk_dir = '{}/GB'.format(data_dir)
wales_dir = '{}/Wales'.format(data_dir)

# the field list for each data set can be quickly viewed using the get_overview function,
# and debug_print dumps the data to console

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


def write_csv(filename, csv_columns, dict_data):
    with open(filename, 'w') as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=csv_columns)
        writer.writeheader()
        for data in dict_data:
            writer.writerow(data)


def make_id(type_id):
    replacements = ['\'', ' &', ',', ' Assembly Const',
                    ' P Const', ' GL', ' ED', ' CP', '_CONST','(', ')',]
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


def build_csv_file(data_dir, shape_group_name):
    """Create the data csv from each shapefile

    Arguments:
        data_dir String -- base dir
        shape_group_name String -- shapefile prefix
    """

    manual_fixes = {'E04001551': 'buckinghamshire_whadden',
                    'E04001852': 'cambridgeshire_whadden',
    }

    nested_groups = {'utw':'uta',
                    'diw':'cty',
                    'mtw':'mtd',
    }

    seen_ids = []

    rows = []
    shape_file = '{}/{}'.format(data_dir, shape_group_name)
    for record in read_records(shape_file):
        # skip these they're just to make maps nice
        if record[12] == 'FILLER AREA':
            continue

        row = {}

        # wmc, saw, etc
        division_type = record[1].lower()

        # in some data files, the record[3] field DESCRIPTIO
        # works fine, in others it would produce dupes
        if division_type in nested_groups:
            parent_id = '{}:{}/'.format(nested_groups[division_type],
                                    make_id(record[3]))
            local_id = make_id(record[0])
        else:
            parent_id = ''
            local_id = make_id(record[0])

        # don't assign record[8] to row['ordnance_id] yet to save csv order
        if record[8] in manual_fixes:
            local_id = manual_fixes[record[8]]

        row['id'] = '{}/{}{}:{}'.format(ocd_base, parent_id, division_type, local_id)
        row['name'] = make_name(record[0])

        if str(record[8]) != '999999999':
            row['ordnance_id'] = record[8]
        else:
            row['ordnance_id'] = ''

        row['sameAs'] = ''

        # they represent aliased rows with (B) (maybe to fix dupes?)
        # but there seem to be some (B) without an original,
        # but there are references to both versions in public data...
        # so add an alternate without the B that sameAs's to this
        if '(B)' in record[0]:
            clean_record = record[0].replace(' (B)','').replace(' (b)','')
            original_id = make_id(clean_record)
            original_name = make_name(clean_record)
            original_ocd = '{}/{}:{}'.format(ocd_base, division_type, original_id)
            if original_ocd not in seen_ids:
                original_row = {}
                original_row['id'] = original_ocd
                original_row['name'] = original_name
                original_row['ordnance_id'] = ''
                original_row['sameAs'] = row['id']
                rows.append(original_row)
                seen_ids.append(original_ocd)
                # sadly theres no way to know the OS id from here

        if row['id'] not in seen_ids:
            seen_ids.append(row['id'])
            rows.append(row)


    group_name = shape_group_name.replace('_region', '')
    csv_filename = 'identifiers/country-uk/{}.csv'.format(group_name)
    write_csv(csv_filename, rows[0].keys(), rows)


def build_welsh_csv(data_dir):
    # community_ward_region
    shape_file = '{}/{}'.format(data_dir, 'community_ward_region')
    rows = []

    communities = []
    for record in read_records(shape_file):
        row = {}
        if isinstance(record[0], bytes):
            record[0] = record[0].decode('latin-1')

        # data error has Llanrumney listed as a CCOMMUNITY
        if record[1] == 'COMMUNITY' or record[1] == 'CCOMMUNITY':
            local_id = make_id(record[0])
            row['id'] = '{}/community:{}'.format(ocd_base, local_id)
        elif record[1] == 'COMMUNITY WARD':
            # In this data Ordanance lists out the wards that make up a community council,
            # but not the base community for the council,
            # because it's not an electoral division
            # it is a legislative body though, so add it here
            if record[2] not in communities:
                community_row = {}
                community_id = make_id(record[2])
                community_row['id'] = '{}/community:{}'.format(ocd_base, community_id)
                community_row['name'] = record[2]
                rows.append(community_row)

            local_id = make_id(record[0])
            parent_id = make_id(record[2])
            row['id'] = '{}/community:{}/community_ward:{}'.format(ocd_base, parent_id, local_id)
        elif record[1] == 'NON-COMMUNITY WARD':
            local_id = make_id(record[0])
            row['id'] = '{}/non_community_ward:{}'.format(ocd_base, local_id)

        row['name'] = record[0]
        rows.append(row)

    csv_filename = 'identifiers/country-uk/wales_communities.csv'
    write_csv(csv_filename, rows[0].keys(), rows)


ocd_base = 'ocd-division/country:uk'

# To see what these files contain,
# debug_print('{}/{}'.format(data_dir, 'westminster_const_region'))

base = [{'id':'ocd-division/country:uk',
        'name': 'United Kingdom of Great Britain and Northern Ireland'}]

write_csv('identifiers/country-uk/uk.csv', ['id','name'], base)

build_csv_file(uk_dir, 'westminster_const_region')
build_csv_file(uk_dir, 'scotland_and_wales_const_region')
build_csv_file(uk_dir, 'greater_london_const_region')
build_csv_file(uk_dir, 'county_region')
build_csv_file(uk_dir, 'unitary_electoral_division_region')
build_csv_file(uk_dir, 'parish_region')
build_csv_file(uk_dir, 'district_borough_unitary_ward_region')
build_csv_file(uk_dir, 'district_borough_unitary_region')
build_csv_file(uk_dir, 'county_electoral_division_region')
build_welsh_csv(wales_dir)