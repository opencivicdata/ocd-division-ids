#!/usr/bin/env python
from __future__ import print_function
import re
import sys
import csv
import urllib2
import argparse
import collections

import us

""" List of FUNCSTAT codes:
    A - active government
    B - partially consolidated government
    C - fully consolidated government
    F - ficticious entities created to fulfill
    G - subordinate government
    I - inactive government
    N - nonfunctioning entity
    S - statistical entity
"""

class TabDelimited(csv.Dialect):
    delimiter = '\t'
    quoting = csv.QUOTE_NONE
    lineterminator = '\n\r'


TYPES = {
    'county': {
        'url': 'http://www.census.gov/geo/www/gazetteer/files/counties_list_{fips}.txt',
        'endings': (' County', ' City and Borough', ' Borough', ' Census Area',
                    ' Municipality', ' Parish', ' city'),
        'row_test': lambda row: row['USPS'] != 'DC'
    },
    'place': {
        'url': 'http://www.census.gov/geo/www/gazetteer/files/2010_place_list_{fips}.txt',
        'endings': (' CDP', ' municipality', ' city', ' town', ' village',
                    ' borough', ' city and borough'),
        'row_test': lambda row: row['FUNCSTAT'] == 'A'
    },
    'subdiv': {
        'url': 'http://www.census.gov/geo/www/gazetteer/files/county_sub_list_{fips}.txt',
        'endings': (' CDP', ' municipality', ' city', ' town', ' village',
                    ' borough', ' city and borough'),
        'row_test': lambda row: row['FUNCSTAT10'] == 'A'
    }
}


def make_id(state, **kwargs):
    if len(kwargs) > 1:
        raise ValueError('only one kwarg is allowed for make_id')
    type, type_id = kwargs.items()[0]
    if not re.match('^[a-z]+$', type):
        raise ValueError('type must match [a-z]+ [%s]' % type)
    type_id = re.sub('[^a-z0-9~_.-]', '~', type_id.replace(' ', '-'))
    return 'ocd-division/country:us/state:{state}/{type}:{type_id}'.format(
        state=state, type=type, type_id=type_id)


def process_file(state, entity_type, filehandle):
    rows = csv.DictReader(filehandle, dialect=TabDelimited)
    seen = collections.Counter()
    places = []

    row_test = TYPES[entity_type]['row_test']

    for row in rows:
        if row['USPS'].lower() == state and row_test(row):

            name = row['NAME']

            for ending in TYPES[entity_type]['endings']:
                if name.endswith(ending):
                    name = name.replace(ending, '')
                    subtype = ending.replace(' ', '_').lower()
                    break
            else:
                if ('Anaconda' not in name and
                    'Carson City' != name):
                    raise ValueError('unknown ending: ' + name)

            name = name.lower().replace(' ', '_')
            seen[name] += 1
            places.append((name, subtype))

    for name, subtype in places:
        if seen[name] != 1:
            name += subtype.lower()
        print(make_id(state=state.lower(), **{entity_type: name}))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Generate OCD ids from Census place files')
    parser.add_argument('state', type=str, default=None,
                        help='state to extract')
    parser.add_argument('type', type=str, default=None,
                        help='type of data to process')
    args = parser.parse_args()

    state = args.state.lower()

    if state == 'all':
        all_fips = [(state.abbr.lower(), state.fips) for state in us.STATES]
    else:
        all_fips = [(state, us.states.lookup(args.state).fips)]

    for state, fips in all_fips:
        data = urllib2.urlopen(TYPES[args.type]['url'].format(fips=fips))
        process_file(state, args.type, data)
