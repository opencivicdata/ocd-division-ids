#!/usr/bin/env python
# Copyright BSD-3 Sunlight Labs, 2013, under the terms of the BSD-3 license.
#   Paul Tagliamonte <paultag@sunlightfoundation.com>

import sys
import csv

# This will help us find out when we have entries that need to be
# matched up. This assumes identifiers are correct.


if len(sys.argv) != 4:
    print "Need the idfile and mapping"
    print "   discrepancies.py identifiers/... mappings/... ocd-division/country:us/state:ma"
    sys.exit(1)

_, idfile, mapping, filter_ = sys.argv


def get_divids(fp):
    with open(fp, 'rb') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        for divid, _ in reader:
            if not divid.startswith(filter_):
                continue
            yield divid


ids = set(get_divids(idfile))
mappings = set(get_divids(mapping))


discrepancies = mappings - ids
for bad_entry in discrepancies:
    print "INVALID", bad_entry


discrepancies = ids - mappings
for bad_entry in discrepancies:
    print "MISSING", bad_entry
