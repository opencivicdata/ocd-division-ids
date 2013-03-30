#!/usr/bin/env python
from __future__ import print_function
import re
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


TYPES = {
    'county': {
        'url': 'http://www.census.gov/geo/www/gazetteer/files/counties_list_{fips}.txt',
        'endings': (' County', ' City and Borough', ' Borough', ' Census Area',
                    ' Municipality', ' Parish', ' city'),
        'funcstat': lambda row: 'F' if row['USPS'] == 'DC' else 'A'
    },
    'place': {
        'url': 'http://www.census.gov/geo/www/gazetteer/files/2010_place_list_{fips}.txt',
        'endings': (' municipality', ' city', ' town', ' village',
                    ' borough', ' city and borough', ' unified government',
                    ' urban county', ' metropolitan government',
                    ' corporation'),
        'funcstat': lambda row: row['FUNCSTAT']
    },
    'subdiv': {
        'url': 'http://www.census.gov/geo/www/gazetteer/files/county_sub_list_{fips}.txt',
        'endings': (' CDP', ' municipality', ' city', ' town', ' village',
                    ' borough', ' city and borough'),
        'funcstat': lambda row: row['FUNCSTAT10']
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

# http://www.census.gov/geo/reference/gtc/gtc_area_attr.html#status

def process_file(state, entity_type, filehandle):
    rows = csv.DictReader(filehandle, dialect=TabDelimited)
    funcstat_count = collections.Counter()
    ids = {}
    duplicates = collections.defaultdict(list)

    # function to extract funcstat value
    funcstat_func = TYPES[entity_type]['funcstat']

    for row in rows:
        funcstat = funcstat_func(row)
        funcstat_count[funcstat] += 1

        # active government
        if funcstat in ('A', 'B'):
            name = row['NAME']

            for ending in TYPES[entity_type]['endings']:
                if name.endswith(ending):
                    name = name.replace(ending, '')
                    subtype = ending.replace(' ', '_').lower()
                    break
            else:
                if (name not in ('Anaconda-Deer Lodge County',
                                 'Hartsville/Trousdale County',
                                 'Carson City',
                                )):
                    raise ValueError('unknown ending: ' + name)
                subtype = None

            name = name.lower().replace(' ', '_')

            id = make_id(state=state.lower(), **{entity_type: name})
            if id in ids:
                duplicates[id].append(row)
                duplicates[id].append(ids.pop(id))
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

    for id in sorted(ids):
        print(id)

    print(state, ' | '.join('{0}: {1}'.format(k,v)
                            for k,v in funcstat_count.most_common()),
          file=sys.stderr)
    #if duplicates:
    for id, sources in duplicates.iteritems():
        print(state, 'duplicate', id, file=sys.stderr)
        for source in sources:
            print('    ', source['NAME'], funcstat_func(source), source['GEOID'],
                  file=sys.stderr)

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
