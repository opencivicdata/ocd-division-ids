#!/usr/bin/env python
from __future__ import print_function
import re
import os
import sys
import csv
import glob
import argparse
import collections


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='verify published CSV files')
    parser.add_argument('country', type=str, default=None,
                        help='country to verify')
    args = parser.parse_args()

    country = args.country.lower()

    ids = collections.defaultdict(list)
    seen_parents = set()
    types = collections.Counter()

    duplicates = 0

    for filename in glob.glob('identifiers/country-{0}/*.csv'.format(country)):
        for name, id_ in csv.reader(open(filename)):
            # check for dupes
            if id_ in ids:
                duplicates += 1
                print('Duplicate ID {0} seen in {1}, and {2}'.format(
                    id_, ', '.join(ids[id_]), filename))
            ids[id_].append(filename)

            # check parents
            parent, endpiece = id_.rsplit('/', 1)
            seen_parents.add(parent)

            # count types
            type_ = endpiece.split(':')[0]
            types[type_] += 1

    if not duplicates:
        print('no duplicates')

    seen_parents -= set(ids.keys())
    print('{0} unknown parents'.format(len(seen_parents)))
    for parent in seen_parents:
        print('   ', parent)

    for type_, count in types.most_common():
        print(type_, count)
