import shapefile
import csv
import re

# Note: This requires the UK Ordnance Survey Electoral Boundaries dataset,
# which is free and liberally licensed, but requires agreeing to a license and
# downloading via an emailed link from their site.
# https://www.ordnancesurvey.co.uk/opendatadownload/products.html#BDLINE

# it also assumes pyshp -- pip3 install pyshp

# Change this to your download location
data_dir = 'bdline_essh_gb/Data'
uk_dir = '{}/GB'.format(data_dir)
wales_dir = '{}/Wales'.format(data_dir)
cerem_dir = '{}/Supplementary_Ceremonial'.format(data_dir)

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
                    ' P Const', ' GL', ' ED', ' CP', '_CONST', '(', ')', ]
    for replacement in replacements:
        type_id = type_id.replace(replacement, '')

    regex_replacements = [r' County$',
                          r'_county$',
                          r' District$',
                          r'_district$',
                          r' Authority$',
                          r'_authority$',
                          ]
    for replacement in regex_replacements:
        type_id = re.sub(replacement, '', type_id, flags=re.IGNORECASE)

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


def build_csv_file(data_dir, shape_group_name, potential_parents):
    """Create the data csv from each shapefile

    Arguments:
        data_dir String -- base dir
        shape_group_name String -- shapefile prefix
        potential_parents -- object of {"<type>:<id>" : "<full_ocd_id">} to resolve cases where we only have the direct parent, but need the grandparent(s) to build a correct ID
    """
    ocd_base = 'ocd-division/country:uk'

    # https://www.ordnancesurvey.co.uk/business-and-government/help-and-support/web-services/administrative-boundaries.html
    nested_groups = {'utw': 'uta',
                     'ute': 'uta',
                     'diw': 'cty',
                     'dis': 'cty',
                     'ced': 'cty',
                     'mtw': 'mtd',
                     'lbo': 'gla',
                     'lac': 'gla',
                     'lbw': 'gla',
                     'spc': 'spe',
                     'cpc': 'uta',
                     }

    seen_ids = []
    rows = []
    shape_file = '{}/{}'.format(data_dir, shape_group_name)
    for record in read_records(shape_file):
        # skip these they're just to make maps nice
        if record[12] == 'FILLER AREA':
            continue

        row = {}

        division_type = record[1].lower()

        if division_type in nested_groups:
            parent_type = nested_groups[division_type]

            # cpc (parishes) can be children of a few different types
            if division_type == 'cpc':
                if record[3] == 'COUNTY_DURHAM' or record[3] == 'COUNTY_OF_HEREFORDSHIRE':
                    # County Durham is not a county...
                    parent_type = 'uta'
                elif 'COUNTY' in record[3]:
                    parent_type = 'cty'
                elif 'DISTRICT' in record[3]:
                    parent_type = 'mtd'
                elif record[3] == 'GREATER_LONDON_AUTHORITY':
                    parent_type = 'gla'

            # create a key for the parent, and then look it up in the potential_parents
            # object to get the full ID, which may include multiple levels of
            # grandparents
            parent_key = '{}:{}'.format(parent_type, make_id(record[3]))
            if parent_key in potential_parents:
                parent_id = potential_parents[parent_key]
                local_id = make_id(record[0])
            else:
                print("Missing parent record")
                print("-----")
                print(shape_group_name)
                print(parent_key)
                print(record)
        else:
            parent_id = ocd_base
            local_id = make_id(record[0])

        row['id'] = '{}/{}:{}'.format(parent_id, division_type, local_id)
        row['name'] = make_name(record[0])

        if str(record[8]) != '999999999':
            row['ordnance_id'] = record[8]
        else:
            row['ordnance_id'] = ''

        row['sameAs'] = ''

        # Ordnance represents aliased rows with (B) (maybe to fix dupes?)
        # there seem to be some (B) without an original, in this dataset
        # but there are references to both versions in public data...
        # so add an alternate without the (B) that sameAs's to this
        if '(B)' in record[0]:
            clean_record = record[0].replace(' (B)', '').replace(' (b)', '')
            original_id = make_id(clean_record)
            original_name = make_name(clean_record)
            original_ocd = '{}/{}:{}'.format(ocd_base,
                                             division_type, original_id)
            if original_ocd not in seen_ids:
                original_row = {}
                original_row['id'] = original_ocd
                original_row['name'] = original_name
                original_row['ordnance_id'] = ''
                original_row['sameAs'] = row['id']
                rows.append(original_row)
                seen_ids.append(original_ocd)
                potential_parents['{}:{}'.format(division_type, local_id)] = row[
                    'id']

        # there are some dupes in the data
        if row['id'] not in seen_ids:
            seen_ids.append(row['id'])
            potential_parents['{}:{}'.format(division_type, local_id)] = row[
                'id']
            rows.append(row)

    group_name = shape_group_name.replace('_region', '')
    csv_filename = 'identifiers/country-uk/{}.csv'.format(group_name)
    write_csv(csv_filename, rows[0].keys(), rows)
    return potential_parents

# ceremonial counties have thier own data format
def build_ceremonial_csv(data_dir):
    shape_file = '{}/{}'.format(data_dir,
                                'Boundary-line-ceremonial-counties_region')
    rows = []
    for record in read_records(shape_file):
        if record[1] == 'Ceremonial County':
            row = {}
            local_id = make_id(record[0])
            row['id'] = '{}/ceremonial_county:{}'.format(ocd_base, local_id)
            row['name'] = make_name(record[0])
            rows.append(row)

    csv_filename = 'identifiers/country-uk/ceremonial_counties.csv'
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
            row['id'] = '{}/welsh_community:{}'.format(ocd_base, local_id)
        elif record[1] == 'COMMUNITY WARD':
            # In this data Ordanance lists out the wards that make up a community council,
            # but not the base community for the council,
            # because it's not an electoral division
            # it is a legislative body though, so add it here
            if record[2] not in communities:
                community_row = {}
                community_id = make_id(record[2])
                community_row[
                    'id'] = '{}/welsh_community:{}'.format(ocd_base, community_id)
                community_row['name'] = record[2]
                rows.append(community_row)

            local_id = make_id(record[0])
            parent_id = make_id(record[2])
            row['id'] = '{}/welsh_community:{}/welsh_community_ward:{}'.format(
                ocd_base, parent_id, local_id)
        elif record[1] == 'NON-COMMUNITY WARD':
            local_id = make_id(record[0])
            row['id'] = '{}/welsh_non_community_ward:{}'.format(ocd_base, local_id)

        row['name'] = record[0]
        rows.append(row)

    csv_filename = 'identifiers/country-uk/wales_communities.csv'
    write_csv(csv_filename, rows[0].keys(), rows)


ocd_base = 'ocd-division/country:uk'

# To see what these files contain,
# debug_print('{}/{}'.format(data_dir, 'westminster_const_region'))

base = [{'id': 'ocd-division/country:uk',
         'name': 'United Kingdom of Great Britain and Northern Ireland'},
        ]

write_csv('identifiers/country-uk/uk.csv', ['id', 'name'], base)

# some entities have multiple parents
# but only give you the information to get one level up
potential_parents = {}

potential_parents = build_csv_file(uk_dir, 'county_region', potential_parents)
potential_parents = build_csv_file(
    uk_dir, 'westminster_const_region', potential_parents)
potential_parents = build_csv_file(
    uk_dir, 'county_electoral_division_region', potential_parents)
potential_parents = build_csv_file(
    uk_dir, 'greater_london_const_region', potential_parents)
potential_parents = build_csv_file(
    uk_dir, 'district_borough_unitary_region', potential_parents)
potential_parents = build_csv_file(
    uk_dir, 'district_borough_unitary_region', potential_parents)
potential_parents = build_csv_file(uk_dir, 'parish_region', potential_parents)
potential_parents = build_csv_file(
    uk_dir, 'european_region_region', potential_parents)
potential_parents = build_csv_file(
    uk_dir, 'district_borough_unitary_ward_region', potential_parents)
potential_parents = build_csv_file(
    uk_dir, 'scotland_and_wales_region_region', potential_parents)
potential_parents = build_csv_file(
    uk_dir, 'scotland_and_wales_const_region', potential_parents)

build_welsh_csv(wales_dir)
build_ceremonial_csv(cerem_dir)

# debug_print('{}/{}'.format(uk_dir, 'scotland_and_wales_const_region'))
# print(get_overview('{}/{}'.format(uk_dir, 'greater_london_const_region')))
