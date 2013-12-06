#!/usr/bin/env python
# Convert Gaz data -> id mappings (GEOID -> ocd-division)
# Copyright (c) Sunlight Labs, 2013, under the terms of the BSD-3 license.
#   Paul Tagliamonte <paultag@sunlightfoundation.com>

from collections import OrderedDict
import codecs
import csv
import sys
import re
import us
import os

# Right, so, first of all, we've got is the Gaz file, the current
# ID mapping to Geo-IDs, let's generate a 1-to-1 mapping of ID identifiers
# to maps.


IDENTIFIERS = {
    "lower": "identifiers/country-us/us_state_leg_lower.csv",
    "upper": "identifiers/country-us/us_state_leg_upper.csv",
}

SOURCE_DATA = {
    "lower": "scripts/source-data/Gaz_sldl_national.txt",
    "upper": "scripts/source-data/Gaz_sldu_national.txt",
}

OUTPUT_DIRECTORY = {
    "lower": "mappings/country-us-sldl/",
    "upper": "mappings/country-us-sldu/",
}


class TabDelimited(csv.Dialect):
    delimiter = '\t'
    quoting = csv.QUOTE_NONE
    lineterminator = '\n\r'
    skipinitialspace = True


def get_exception_set():
    csvfile = csv.reader(open('identifiers/country-us/exceptions.txt'))
    return {x[0]: x[1] for x in csvfile}


def make_id(parent=None, **kwargs):
    if len(kwargs) > 1:
        raise ValueError('only one kwarg is allowed for make_id')
    type, type_id = list(kwargs.items())[0]
    if not re.match('^[a-z_]+$', type):
        raise ValueError('type must match [a-z]+ [%s]' % type)
    type_id = type_id.lower()
    type_id = re.sub('\.? ', '_', type_id)
    type_id = re.sub('[^\w0-9~_.-]', '~', type_id, re.UNICODE)
    if parent:
        return '{parent}/{type}:{type_id}'.format(parent=parent, type=type,
                                                  type_id=type_id)
    else:
        return 'ocd-division/country:us/{type}:{type_id}'.format(
            type=type, type_id=type_id)


def extract_district(chamber, state, string):

    hr_name = {
        "lower": "State House",
        "upper": "State Senate",
    }[chamber]

    hr_overrides = {
        "ca": {
            "lower": "Assembly",
        },
        "md": {
            "lower": "State Legislative",
        },
        "nv": {
            "lower": "Assembly",
        },
        "nj": {
            "lower": "General Assembly",
        },
        "ny": {
            "lower": "Assembly",
        },
        "wi": {
            "lower": "Assembly",
        },
    }

    if state in hr_overrides:
        overrides = hr_overrides[state]
        if chamber in overrides:
            hr_name = overrides[chamber]

    regex = "%s (Sub)?[d|D]istrict (?P<district>.*)" % (hr_name)

    if state == 'ma':
        regex = "(?P<district>.*) District"

    if state == 'dc':
        regex = "Ward (?P<district>.*)"

    if state == 'vt':
        regex = "(?P<district>.*) State (Senate|House) District"

    if (state == 'nh' and chamber == 'lower') or (state == 'ak' and chamber == 'lower'):
        regex = "%s (Sub)?[d|D]istrict (?P<district>.*), .*" % (hr_name)

    if state == 'nv' and chamber == 'upper':
        regex = ".* Senatorial District (?P<district>.*)"


    info = re.match(regex, string)
    if info is None:
        print regex
        print string, state
        raise ValueError

    return info.groupdict()['district']


def mangle_name(name):  # Purely best-effort. We'll need to do manual
    # work after. We need to be sure it's sane and sensable anyway, let's
    # just trust it gets the average case fine.
    name = name.lower()
    # name = name.replace("-", "_")
    name = name.replace(",", "")
    name = name.replace("&", "and")
    name = name.replace(" ", "_")

    number_names = OrderedDict(reversed([
        ("first", "1st",),
        ("second", "2nd",),
        ("third", "3rd",),
        ("fourth", "4th",),
        ("fifth", "5th",),
        ("sixth", "6th",),
        ("seventh", "7th",),
        ("eighth", "8th",),
        ("ninth", "9th",),
        ("tenth", "10th",),
        ("eleventh", "11th",),
        ("twelfth", "12th",),
        ("thirtieth", "13th",),
        ("thirteenth", "13th",),
        ("fourteenth", "14th",),
        ("fifteenth", "15th",),
        ("sixteenth", "16th",),
        ("seventeenth", "17th",),
        ("eighteenth", "18th",),
        ("nineteenth", "19th",),
        ("twentieth", "20th",),
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
    ]))

    for number_name, repl in number_names.items():
        name = name.replace(number_name, repl)

    return name


def convert_gaz_file(fpath, state, chamber):
    data = codecs.open(fpath, encoding='latin1')
    rows = csv.DictReader(data, dialect=TabDelimited)

    for row in rows:
        state_ = row['USPS'].lower()

        if state_ != state:
            continue

        state = state_
        string = row['NAME']

        # $ grep "State House Districts not defined" . -r | wc -l
        # 26  # - Yes, seriously.
        if "State House Districts not defined" in string:
            continue

        if "State Senate Districts not defined" in string:
            continue

        if 'Senatorial' in string and state == 'nv':
            continue

        district = extract_district(chamber, state, string)
        district = mangle_name(district)

        kwargs = {}

        if chamber == 'lower':
            kwargs['sldl'] = district

        if chamber == 'upper':
            kwargs['sldu'] = district

        if kwargs == {}:
            raise ValueError

        newid = make_id('ocd-division/country:us/state:%s' % (state), **kwargs)
        geoid = row['GEOID']
        yield (newid, geoid)


def write_mappings(chamber, limit_state=None):
    root = OUTPUT_DIRECTORY[chamber]

    for state in us.STATES:
        sid = state.abbr.lower()
        if limit_state and sid != limit_state:
            continue

        print state
        with open(os.path.join(root, "%s.csv" % (sid)), 'w') as fd:
            for divid, geoid in convert_gaz_file(SOURCE_DATA[chamber], sid, chamber):
                fd.write("%s,%s\n" % (divid, geoid))

if len(sys.argv) > 2:
    if sys.argv[2] == 'all':
        write_mappings(sys.argv[1])
    else:
        write_mappings(sys.argv[1], limit_state=sys.argv[2])
else:
    write_mappings('upper')
    write_mappings('lower')
