#!/usr/bin/env python
from __future__ import print_function
import sys
import csv
import argparse
import collections

from utils import make_id

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


""" Notes on NationalFile_20130210.txt
    Stream: 232381
    Church: 231918
    School: 215327
    Populated Place: 200323
    Locale: 162527
    Building: 140413
    Cemetery: 140082
    Reservoir: 75079
    Summit: 70999
    Valley: 70263
    Lake: 69802
    Park: 68924
    Civil: 63909
    Post Office: 59717
    Dam: 56969
    Well: 38771
    Spring: 38600
    Mine: 36041
    Airport: 23094
    Canal: 21655
    Island: 20555
    Tower: 16795
    Cape: 16473
    Hospital: 15654
    Ridge: 15185
    Crossing: 13166
    Bay: 13047
    Census: 11587
    Trail: 11013
    Flat: 10546
    Gap: 8433
    Swamp: 7374
    Bridge: 7345
    Bar: 5931
    Oilfield: 4863
    Cliff: 4502
    Basin: 4310
    Channel: 4118
    Gut: 3975
    Military: 2859
    Bend: 2841
    Area: 2563
    Range: 2493
    Falls: 2491
    Beach: 2404
    Pillar: 2095
    Forest: 1302
    Harbor: 1274
    Reserve: 1170
    Rapids: 1117
    Glacier: 1021
    Tunnel: 742
    Bench: 725
    Arch: 725
    Woods: 672
    Levee: 546
    Arroyo: 465
    Slope: 374
    Plain: 289
    Crater: 243
    Lava: 191
    Unknown: 186
    Isthmus: 28
    Sea: 14
"""
