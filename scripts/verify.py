#!/usr/bin/env python3
from __future__ import print_function
import re
import os
import sys
import csv
import glob
import argparse
import collections


VALID_ID_IGNORE_CASE = re.compile(r'^ocd-division/country:[a-z]{2}(/[^\W\d]+:[\w.~-]+)*$', re.U)

def unicode_csv_reader(f, encoding='utf-8'):
    reader = csv.reader(f)
    for row in reader:
        yield [unicode(field, encoding) for field in row]

def utf8_row(row):
    return [field.encode('utf-8') for field in row]

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='verify published CSV files')
    parser.add_argument('country', type=str, default=None,
                        help='country to verify')
    args = parser.parse_args()

    country = args.country.lower()

    ids = collections.defaultdict(list)
    seen_parents = set()
    invalid_ids = set()
    types = collections.Counter()
    all_rows = []

    duplicates = 0

    for filename in glob.glob('identifiers/country-{0}/*.csv'.format(country)):
        print('processing', filename)
        for id_, name in unicode_csv_reader(open(filename)):
            all_rows.append((id_, name))

            # check for dupes
            if id_ in ids:
                duplicates += 1
                print('Duplicate ID {0} seen in {1}, and {2}'.format(
                    id_, ', '.join(ids[id_]), filename))
            ids[id_].append(filename)

            if not VALID_ID_IGNORE_CASE.match(id_):
                invalid_ids.add(id_)

            # check that all characters are lowercase
            if id_.lower() != id_:
                invalid_ids.add(id_)

            # check parents
            parent, endpiece = id_.rsplit('/', 1)
            if parent != 'ocd-division':
                seen_parents.add(parent)

            # count types
            type_ = endpiece.split(':')[0]
            types[type_] += 1

    if not duplicates:
        print('0 duplicates')

    seen_parents -= set(ids.keys())
    print('{0} unknown parents'.format(len(seen_parents)))
    for parent in sorted(seen_parents):
        print('   ', parent)

    print('{0} invalid ids'.format(len(invalid_ids)))
    for i in sorted(invalid_ids):
        print('   ', i)

    print('stats')
    for type_, count in types.most_common():
        print('   ', type_, count)

    # write output file
    if not duplicates and not seen_parents:
        with open('identifiers/country-{0}.csv'.format(country), 'w') as out:
            out = csv.writer(out)
            for row in sorted(all_rows):
                out.writerow(utf8_row(row))

    # do geoid validation too (TODO: add a flag for this)
    seen_in_geoid = set()
    all_geo_rows = list()
    if country == 'us':
        for filename in glob.glob('mappings/us-census-geoids/*.csv'):
            for id_, geoid in unicode_csv_reader(open(filename)):
                seen_in_geoid.add(id_)
                if id_ not in ids:
                    print('unexpected geoid for', id_)
                all_geo_rows.append((id_, geoid))

        #unknown_ids = set(ids.keys()) - seen_in_geoid
        #if not unknown_ids:
        #    print('no missing geoids!')
        #else:
        #    for id in sorted(unknown_ids):
        #        print('missing geoid for id', id)
        with open('mappings/us-census-geoids.csv', 'w') as out:
            out = csv.writer(out)
            for row in sorted(all_geo_rows):
                out.writerow(utf8_row(row))
