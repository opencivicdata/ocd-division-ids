#!/usr/bin/env python
from __future__ import print_function
import sys
import csv
import argparse
import collections

class GazeteerDialect(csv.Dialect):
    delimiter = '|'
    quoting = csv.QUOTE_NONE
    lineterminator = '\n\r'

if __name__ == '__main__':
    # http://geonames.usgs.gov/domestic/download_data.htm
    parser = argparse.ArgumentParser(
        description='Extract features from USGS Gazetteer files.')
    parser.add_argument('filename', type=str, help='name of txt file')
    parser.add_argument('feature', type=str, nargs='?', default=None,
                        help='feature type to extract')
    args = parser.parse_args()
    rows = csv.DictReader(open(args.filename), dialect=GazeteerDialect)
    if args.feature:
        for row in rows:
            if (row['FEATURE_CLASS'] == args.feature and
                '(historical)' not in row['FEATURE_NAME']):
                print(row['FEATURE_NAME'])
    else:
        features = collections.Counter()
        for row in rows:
            features[row['FEATURE_CLASS']] += 1
        for k, v in features.most_common():
            print(k, v, sep=': ')
