#!/usr/bin/env python
from __future__ import print_function
import re
import os
import sys
import csv
import urllib2
import argparse
import collections

import us

class TabDelimited(csv.Dialect):
    delimiter = '\t'
    quoting = csv.QUOTE_NONE
    lineterminator = '\n\r'
    skipinitialspace = True


TYPE_MAPPING = {
    # counties
    ' County': 'county',
    # louisiana
    ' Parish': 'parish',
    # independent cities
    ' city': 'place',
    # alaska
    #' City and Borough': 'borough',
    ' Borough': 'borough',
    ' Municipality': 'borough',
    ' Census Area': 'censusarea',

    # places
    ' municipality': 'place',
    ' borough': 'place',
    ' city': 'place',
    ' town': 'place',
    ' village': 'place',

    # subdivs
    ' township': 'place',
    ' plantation': 'place',
}


TYPES = {
    'county': {
        'url': 'http://www.census.gov/geo/maps-data/data/docs/gazetteer/counties_list_{fips}.txt',
        'localfile': os.path.join(os.path.dirname(__file__), 'source-data/Gaz_counties_national.txt'),
        'funcstat': lambda row: 'F' if row['USPS'] == 'DC' else 'A'
    },
    'place': {
        'url': 'http://www.census.gov/geo/maps-data/data/docs/gazetteer/2010_place_list_{fips}.txt',
        'localfile': os.path.join(os.path.dirname(__file__), 'source-data/Gaz_places_national.txt'),
        'funcstat': lambda row: row['FUNCSTAT']
    },
    'subdiv': {
        'url': 'http://www.census.gov/geo/maps-data/data/docs/gazetteer/county_sub_list_{fips}.txt',
        'localfile': os.path.join(os.path.dirname(__file__), 'source-data/Gaz_cousubs_national.txt'),

        'funcstat': lambda row: row['FUNCSTAT10']
    }
}

OVERRIDES = {
    # Alaska lists these twice (lower case = place, upper case=borough)
    'Wrangell city and borough': ('Wrangell', 'place'),
    'Sitka city and borough': ('Sitka', 'place'),
    'Juneau city and borough': ('Juneau', 'place'),
    'Wrangell City and Borough': ('Wrangell', 'borough'),
    'Sitka City and Borough': ('Sitka', 'borough'),
    'Juneau City and Borough': ('Juneau', 'borough'),
    'Yakutat City and Borough': ('Yakutat', 'borough'),

    # places that don't obey the usual naming rules
    'Carson City': ('Carson City', 'place'),
    'Lexington-Fayette urban county': ('Lexington', 'place'),
    'Lynchburg, Moore County metropolitan government': ('Lynchburg', 'place'),
    'Cusseta-Chattahoochee County unified government': ('Cusseta', 'place'),
    'Georgetown-Quitman County unified government': ('Georgetown', 'place'),
    'Webster County unified government': ('Webster County ', 'place'),
    'Ranson corporation': ('Ranson', 'place'),

    # kansas
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
}

def make_id(state, **kwargs):
    if len(kwargs) > 1:
        raise ValueError('only one kwarg is allowed for make_id')
    type, type_id = kwargs.items()[0]
    if not re.match('^[a-z]+$', type):
        raise ValueError('type must match [a-z]+ [%s]' % type)
    type_id = type_id.lower()
    type_id = re.sub('\.? ', '_', type_id)
    type_id = re.sub('[^a-z0-9~_.-]', '~', type_id)
    return 'ocd-division/country:us/state:{state}/{type}:{type_id}'.format(
        state=state, type=type, type_id=type_id)

# http://www.census.gov/geo/reference/gtc/gtc_area_attr.html#status

def process_file(state, types, csvfile, geocsv):
    funcstat_count = collections.Counter()
    type_count = collections.Counter()
    ids = {}
    duplicates = collections.defaultdict(list)

    for entity_type in types:
        data = open(TYPES[entity_type]['localfile'])
        rows = csv.DictReader(data, dialect=TabDelimited)
        # function to extract funcstat value
        funcstat_func = TYPES[entity_type]['funcstat']

        for row in rows:
            # skip any rows not from this state
            if row['USPS'].lower() != state.lower():
                continue

            row['_FUNCSTAT'] = funcstat = funcstat_func(row)
            funcstat_count[funcstat] += 1

            # active government
            if funcstat in ('A', 'B', 'G'):
                name = row['NAME']

                if name in OVERRIDES:
                    name, subtype = OVERRIDES[name]
                else:
                    for ending, subtype in TYPE_MAPPING.iteritems():
                        if name.endswith(ending):
                            name = name.replace(ending, '')
                            break
                    else:
                        raise ValueError('unknown ending: ' + name)

                type_count[subtype] += 1

                id = make_id(state=state.lower(), **{subtype: name})
                if id in ids:
                    id1 = make_id(state=state.lower(),
                                  **{subtype: row['NAME']})
                    row2 = ids.pop(id)
                    id2 = make_id(state=state.lower(),
                                  **{subtype: row2['NAME']})
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

            elif funcstat in ('I', 'F', 'N', 'S', 'C'):
                # inactive/fictitious/nonfunctioning/statistical/consolidated
                pass
            else:
                # unhandled FUNCSTAT type
                raise Exception(row)

    # write ids out
    for id, row in sorted(ids.iteritems()):
        csvfile.writerow((row['NAME'], id))
        if geocsv:
            geocsv.writerow((id, row['GEOID']))

    print(state, ' | '.join('{0}: {1}'.format(k,v)
                            for k,v in funcstat_count.most_common()),
          file=sys.stderr)
    print(state, ' | '.join('{0}: {1}'.format(k,v)
                            for k,v in type_count.most_common()),
          file=sys.stderr)
    #if duplicates:
    for id, sources in duplicates.iteritems():
        print(state, 'duplicate', id, file=sys.stderr)
        for source in sources:
            print('    ', source['NAME'], source['_FUNCSTAT'],
                  source['GEOID'], file=sys.stderr)

if __name__ == '__main__':
    CONST = '~~~const~~~'

    parser = argparse.ArgumentParser(
        description='Generate OCD ids from Census place files')
    parser.add_argument('state', type=str, default=None,
                        help='state to extract')
    parser.add_argument('types', type=str, nargs='*', default=TYPES.keys(),
                        help='types of data to process')
    parser.add_argument('--csv', help='name of CSV file', nargs='?',
                        const=CONST)
    parser.add_argument('--geo', help='write a CSV file of Geo IDs', nargs='?',
                        const=CONST)
    args = parser.parse_args()

    state = args.state.lower()

    if args.csv == CONST:
        args.csv = 'identifiers/country-us/state-{0}-census.csv'.format(state)
    if args.geo == CONST:
        args.geo = 'mappings/country-us/state-{0}-id_to_censusgeo.csv'.format(state)

    if args.csv:
        csvfile = csv.writer(open(args.csv, 'w'))
    else:
        csvfile = csv.writer(sys.stdout)

    if args.geo:
        geocsv = csv.writer(open(args.geo, 'w'))
    else:
        geocsv = None

    if state == 'all':
        all_fips = [(state.abbr.lower(), state.fips) for state in us.STATES]
    else:
        all_fips = [(state, us.states.lookup(args.state).fips)]

    for state, fips in all_fips:
        process_file(state, args.types, csvfile, geocsv)

