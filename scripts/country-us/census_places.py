#!/usr/bin/env python
import re
import os
import sys
import csv
import codecs
import urllib.request
import zipfile
import argparse
import collections
import us


class TabDelimited(csv.Dialect):
    delimiter = '\t'
    quoting = csv.QUOTE_NONE
    lineterminator = '\n\r'
    skipinitialspace = True


def get_exception_set():
    csvfile = csv.reader(open('identifiers/country-us/exceptions.csv'))
    return set(x[0] for x in csvfile)


def _ordinal(value):
    if value == 0:
        return 'At-Large'

    if (value % 100) // 10 != 1:
        if value % 10 == 1:
            ordval = 'st'
        elif value % 10 == 2:
            ordval = 'nd'
        elif value % 10 == 3:
            ordval = 'rd'
        else:
            ordval = 'th'
    else:
        ordval = 'th'

    return '{}{}'.format(value, ordval)

BASE_URL = 'http://www2.census.gov/geo/gazetteer/2013_Gazetteer/'
CD_111 = 'https://www.census.gov/geo/maps-data/data/docs/gazetteer/Gaz_cd111_national.zip'


TYPES = {
    'county': {
        'zip': '2013_Gaz_counties_national.zip',
        'funcstat': lambda row: 'F' if row['USPS'] == 'DC' else 'A',
        'type_mapping': {
            ' County': 'county',
            ' Parish': 'parish',
            ' Borough': 'borough',
            ' Municipality': 'borough',
            ' Census Area': 'census_area',
            ' Municipio': 'municipio',
        },
        'overrides': {
            'Wrangell City and Borough': ('Wrangell', 'borough'),
            'Sitka City and Borough': ('Sitka', 'borough'),
            'Juneau City and Borough': ('Juneau', 'borough'),
            'Yakutat City and Borough': ('Yakutat', 'borough'),
        },
        'id_overrides': { }
    },
    'place': {
        'zip': '2013_Gaz_place_national.zip',
        'funcstat': lambda row: row['FUNCSTAT'],
        'type_mapping': {
            ' municipality': 'place',
            ' borough': 'place',
            ' city': 'place',
            ' town': 'place',
            ' village': 'place',
        },
        'overrides': {
            'Wrangell city and borough': ('Wrangell', 'place'),
            'Sitka city and borough': ('Sitka', 'place'),
            'Juneau city and borough': ('Juneau', 'place'),
            'Lexington-Fayette urban county': ('Lexington', 'place'),
            'Lynchburg, Moore County metropolitan government': ('Lynchburg', 'place'),
            'Cusseta-Chattahoochee County unified government': ('Cusseta', 'place'),
            'Georgetown-Quitman County unified government': ('Georgetown', 'place'),
            'Anaconda-Deer Lodge County': ('Anaconda', 'place'),
            'Hartsville/Trousdale County': ('Hartsville', 'place'),
            'Webster County unified government': ('Webster County ', 'place'),
            'Ranson corporation': ('Ranson', 'place'),
            'Carson City': ('Carson City', 'place'),
            'Princeton': ('Princeton', 'place'),
        },
        'id_overrides': {
            '2756680': ('St. Anthony (Hennepin/Ramsey Counties)', 'place'),
            '2756698': ('St. Anthony (Stearns County)', 'place'),
            '4861592': ('Reno (Lamar County)', 'place'),
            '4861604': ('Reno (Parker County)', 'place'),
            '4840738': ('Lakeside (San Patricio County)', 'place'),
            '4840744': ('Lakeside (Tarrant County)', 'place'),
            '4853154': ('Oak Ridge (Cooke County)', 'place'),
            '4853160': ('Oak Ridge (Kaufman County)', 'place'),
            '4253336': ('Newburg borough (Clearfield County)', 'place'),
            '4253344': ('Newburg borough (Cumberland County)', 'place'),
            '4214584': ('Coaldale borough (Bedford County)', 'place'),
            '4214600': ('Coaldale borough (Schuylkill County)', 'place'),
            '4243064': ('Liberty borough (Allegheny County)', 'place'),
            '4243128': ('Liberty borough (Tioga County)', 'place'),
            '4261496': ('Pleasantville borough (Bedford County)', 'place'),
            '4261512': ('Pleasantville borough (Venango County)', 'place'),
            '4237880': ('Jefferson borough (Greene County)', 'place'),
            '4237944': ('Jefferson borough (York County)', 'place'),
            '4212184': ('Centerville borough (Crawford County)', 'place'),
            '4212224': ('Centerville borough (Washington County)', 'place'),
        }
    },
    'subdiv': {
        'zip': '2013_Gaz_cousubs_national.zip',
        'funcstat': lambda row: row['FUNCSTAT'],
        'type_mapping': {
            ' town': 'place',
            ' village': 'place',
            ' township': 'place',
            ' plantation': 'place',
        },
        'overrides': {
            'Township 1': ('Township 1', 'place'),
            'Township 2': ('Township 2', 'place'),
            'Township 3': ('Township 3', 'place'),
            'Township 4': ('Township 4', 'place'),
            'Township 5': ('Township 5', 'place'),
            'Township 6': ('Township 6', 'place'),
            'Township 7': ('Township 7', 'place'),
            'Township 8': ('Township 8', 'place'),
            'Township 9': ('Township 9', 'place'),
            'Township 10': ('Township 10', 'place'),
            'Township 11': ('Township 11', 'place'),
            'Township 12': ('Township 12', 'place'),
        },
        'id_overrides': { }
    },
}

# list of rules for how to handle subdivs
#   prefix - these are strictly within counties and need to be id'd as such
#   town - these are the equivalent of places
SUBDIV_RULES = {
    'ct': 'town',
    'il': 'prefix',
    'in': 'prefix',
    'ks': 'prefix',
    'ma': 'town',
    'me': 'town',
    'mi': 'prefix',
    'mn': 'prefix',
    'mo': 'prefix',
    'nd': 'prefix',
    'ne': 'prefix',
    'nh': 'town',
    'nj': 'prefix',
    'ny': 'prefix',
    'oh': 'prefix',
    'pa': 'prefix',
    'ri': 'town',
    'sd': 'prefix',
    'vt': 'town',
    'wi': 'prefix',
}


def make_id(parent=None, **kwargs):
    if len(kwargs) > 1:
        raise ValueError('only one kwarg is allowed for make_id')
    type, type_id = list(kwargs.items())[0]
    if not re.match('^[a-z_]+$', type):
        raise ValueError('type must match [a-z]+ [%s]' % type)
    type_id = type_id.lower()
    if type == 'state' and type_id == 'pr':
        type = 'territory'
    elif type == 'state' and type_id == 'dc':
        type = 'district'
    type_id = re.sub('\.? ', '_', type_id)
    type_id = re.sub('[^\w0-9~_.-]', '~', type_id, re.UNICODE)
    if parent:
        return '{parent}/{type}:{type_id}'.format(parent=parent, type=type, type_id=type_id)
    else:
        return 'ocd-division/country:us/{type}:{type_id}'.format(type=type, type_id=type_id)


def open_gaz_zip(url):
    print('fetching zipfile', url)
    zf, _ = urllib.request.urlretrieve(url)
    zf = zipfile.ZipFile(zf)
    localfile = zf.extract(zf.filelist[0], '/tmp/')
    data = codecs.open(localfile, encoding='latin1')
    return csv.DictReader(data, dialect=TabDelimited)


def process_cds():
    csvfile = csv.writer(open('identifiers/country-us/us_congressional_districts.csv', 'w'))
    geocsv = csv.writer(open('mappings/us-cds-geoid.csv', 'w'))
    ids = set()

    CD_URLS = (
        ('', BASE_URL + '2013_Gaz_113CDs_national.zip'),
        (' (obsolete as of 2012)', 
         'https://www.census.gov/geo/maps-data/data/docs/gazetteer/Gaz_cd111_national.zip')
    )

    for suffix, url in CD_URLS:
        rows = open_gaz_zip(url)
        for row in rows:
            state = us.states.lookup(row['USPS'])
            district = row['GEOID'][2:]

            # placeholders and at-large districts
            if district in ('00', 'ZZ', '98'):
                continue

            parent_id = make_id(state=row['USPS'].lower())
            id = make_id(parent_id, cd=str(int(district)))

            # already made this ID
            if id in ids:
                continue

            ids.add(id)
            district = _ordinal(int(district))
            name = "{}'s {} congressional district".format(state, district) + suffix

            csvfile.writerow((id, name))
            geocsv.writerow((id, row['GEOID']))

def process_sld(district_type):
    rows = open_gaz_zip(BASE_URL + '2013_Gaz_{}_national.zip'.format(district_type))
    csvfile = csv.writer(open('identifiers/country-us/us_{}.csv'.format(district_type), 'w'))
    geocsv = csv.writer(open('mappings/us-{}-geoid.csv'.format(district_type), 'w'))
    for row in rows:
        state = us.states.lookup(row['USPS'])

        # skip the undefined districts
        if 'not defined' in row['NAME']:
            continue

        district = row['NAME']
        replacements = (
            # Puerto Rico
            ('Puerto Rico State Senate District VIII', '8'),
            ('Puerto Rico State Senate District VII', '7'),
            ('Puerto Rico State Senate District VI', '6'),
            ('Puerto Rico State Senate District V', '5'),
            ('Puerto Rico State Senate District IV', '4'),
            ('Puerto Rico State Senate District III', '3'),
            ('Puerto Rico State Senate District II', '2'),
            ('Puerto Rico State Senate District I', '1'),
            # DC
            ('Ward', ''),
            # others
            ('State Senate District', ''),
            ('State House District', ''),
            ('State Legislative District', ''),
            ('State Legislative Subdistrict', ''),
            ('County No. ', ''),
            ('General Assembly District', ''),
            ('State Assembly District', ''),
            ('Assembly District', ''),
            ('HD-', ''),
            # VT
            ('Grand-Isle', 'Grand Isle'),
            # MA
            (',', ''),
            ('&', 'and'),
            ("First", "1st",),
            ("Second", "2nd",),
            ("Third", "3rd",),
            ("Fourth", "4th",),
            ("Fifth", "5th",),
            ("Sixth", "6th",),
            ("Seventh", "7th",),
            ("Eighth", "8th",),
            ("Ninth", "9th",),
            ("Tenth", "10th",),
            ("Eleventh", "11th",),
            ("Twelfth", "12th",),
            ("Thirtieth", "13th",),
            ("Thirteenth", "13th",),
            ("Fourteenth", "14th",),
            ("Fifteenth", "15th",),
            ("Sixteenth", "16th",),
            ("Seventeenth", "17th",),
            ("Eighteenth", "18th",),
            ("Nineteenth", "19th",),
            ("Twentieth", "20th",),
            ("twenty_first", "21st",),
            ("twenty_second", "22nd",),
            ("twenty_third", "23rd",),
            ("twenty_fourth", "24th",),
            ("twenty_fifth", "25th",),
            ("twenty_sixth", "26th",),
            ("twenty_seventh", "27th",),
            ("twenty_eighth", "28th",),
            ("twenty_ninth", "29th",),
            ("thirty", "31st",),
            ("thirty_first", "31st",),
            ("thirty_second", "32nd",),
            ("thirty_third", "33rd",),
            ("thirty_fourth", "34th",),
            ("thirty_fifth", "35th",),
            ("thirty_sixth", "36th",),
            ("thirty_seventh", "37th",),
            ("thirty_eighth", "38th",),
            ("thirty_ninth", "39th",),
            (' District', ''),
        )
        for k, v in replacements:
            district = district.replace(k, v)
        district = district.strip().lstrip('0')

        # CHANGE: undo district lowercasing
        name = "{} {}".format(state, row['NAME'].replace('District', 'district'))
        parent_id = make_id(state=row['USPS'].lower())
        if row['USPS'] == 'DC':
            id = make_id(parent_id, **{'ward':district})
        else:
            id = make_id(parent_id, **{district_type:district})

        csvfile.writerow((id, name))
        geocsv.writerow((id, row['GEOID']))


def process_types(types):
    funcstat_count = collections.Counter()
    type_count = collections.Counter()
    counties = {}
    ids = {}
    # list of rows that produced an id
    duplicates = collections.defaultdict(list)
    # load exceptions from file
    exceptions = get_exception_set()
    csvfile = csv.writer(open('identifiers/country-us/us_census_places.csv', 'w'))
    geocsv = csv.writer(open('mappings/us-census-places-geoids.csv', 'w'))

    for entity_type in types:
        url = BASE_URL + TYPES[entity_type]['zip']
        funcstat_func = TYPES[entity_type]['funcstat']
        overrides = TYPES[entity_type]['overrides']
        id_overrides = TYPES[entity_type]['id_overrides']
        rows = open_gaz_zip(url)

        for row in rows:
            state = row['USPS'].lower()
            name = row['NAME']

            subdiv_rule = SUBDIV_RULES.get(state)
            parent_id = make_id(state=state)

            row['_FUNCSTAT'] = funcstat = funcstat_func(row)
            funcstat_count[funcstat] += 1

            # skip inactive/fictitious/nonfunctioning/statistical/consolidated
            # http://www.census.gov/geo/reference/gtc/gtc_area_attr.html#status
            if funcstat in ('F', 'N', 'S', 'C', 'G'):
                continue
            if funcstat not in ('A', 'B', 'I'):
                # unknown type
                raise Exception(row)
            if entity_type == 'subdiv' and not subdiv_rule:
                raise Exception('unexpected subdiv in {}: {}'.format(state, row))

            if name in overrides:
                name, subtype = overrides[name]
            elif row['GEOID'] in id_overrides:
                name, subtype = id_overrides[row['GEOID']]
            else:
                for ending, subtype in TYPES[entity_type]['type_mapping'].items():
                    if name.endswith(ending):
                        name = name.replace(ending, '')
                        break
                else:
                    # skip independent cities indicated at county level
                    if (entity_type == 'county' and (name.endswith(' city') or
                                                     name == 'Carson City')):
                        continue
                    else:
                        raise ValueError('unknown ending: {} for {}'.format(name, row))

            type_count[subtype] += 1

            if entity_type == 'subdiv' and subdiv_rule == 'prefix':
                # find county id
                for geoid, countyid in counties.items():
                    if row['GEOID'].startswith(geoid):
                        id = make_id(parent=countyid, **{subtype: name})
                        break
                else:
                    raise Exception('{} had no parent county'.format(row))
            elif entity_type != 'subdiv' or subdiv_rule == 'town':
                id = make_id(parent=parent_id, **{subtype: name})

            # duplicates
            if id in ids:
                id1 = make_id(parent=parent_id, **{subtype: row['NAME']})
                row2 = ids.pop(id)
                id2 = make_id(parent=parent_id, **{subtype: row2['NAME']})
                if id1 != id2:
                    ids[id1] = row
                    ids[id2] = row2
                else:
                    duplicates[id].append(row)
                    duplicates[id].append(row2)
            elif id in duplicates:
                duplicates[id].append(row)
            else:
                ids[id] = row
                if entity_type == 'county':
                    counties[row['GEOID']] = id

    # write ids out
    for id, row in sorted(ids.items()):
        if id not in exceptions:
            csvfile.writerow((id, row['NAME']))
            geocsv.writerow((id, row['GEOID']))

    print(' | '.join('{}: {}'.format(k,v) for k,v in funcstat_count.most_common()))
    print(' | '.join('{}: {}'.format(k,v) for k,v in type_count.most_common()))

    for id, sources in duplicates.items():
        error = '{} duplicate {}\n'.format(state, id)
        for source in sources:
            error += '    {NAME} {_FUNCSTAT} {GEOID}'.format(**source)
        raise Exception(error)


if __name__ == '__main__':
    #process_types(('county', 'place', 'subdiv'))
    process_cds()
    #process_sld('sldu')
    #process_sld('sldl')
