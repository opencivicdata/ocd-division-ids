# Copyright (c) 2013, Sunlight Foundation
#   - Paul R. Tagliamonte <paultag@sunlightfoundation.com>
# under the terms and conditions of the BSD-3 license.

from dbfpy import dbf
import json
import us
import sys
import re


DISTRICT = re.compile("Congressional District (?P<district>\d+)")

AT_LARGE_GEOID = "ocd-division/country:%s/state:%s"
CD_GEOID = "ocd-division/country:%s/state:%s/cd:%s"

MAPPING = []


FILES = {}


def get_file(state):
    if state not in FILES:
        FILES[state] = open("mappings/country-us-cd/%s.csv" % (state), 'w')
    return FILES[state]


db = dbf.Dbf(*sys.argv[1:])
for rec in db:
    state = us.states.lookup(rec['STATEFP10'])
    name = rec['NAMELSAD10']
    geoid = None

    if "at Large" in name:
        geoid = AT_LARGE_GEOID % ("us", state.abbr.lower())
    else:
        district = DISTRICT.match(name).groupdict()['district']
        geoid = CD_GEOID % ("us", state.abbr.lower(), district)

    fd = get_file(state.abbr.lower())
    fd.write("%s,%s\n" % (geoid, rec['GEOID10']))

for k, v in FILES.items():
    v.close()
