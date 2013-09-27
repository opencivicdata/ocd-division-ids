#!/usr/bin/env python
import requests
from fuzzywuzzy import fuzz,process
from operator import itemgetter

"""
Module to parse official ocdid data accept district data, and attempt to
  match given data to official ocdids. Provides ratios data for inexact
  matches and a list of closest matches when searching

Requirements:
Python2.7
Requests
fuzzywuzzy

Constants:
OCDID_DATA -- location to pull ocdid data from, either a file or url
MATCH_RATIO -- lowest valid match ratio accepted
MATCH_LIMIT -- maximum number of matched values returned
SEARCH_CONVERSIONS -- conversions for district search types to valid ocd types

"""
OCDID_DATA = 'https://raw.github.com/opencivicdata/ocd-division-ids/master/identifiers/country-us.csv'
MATCH_RATIO = 90 
MATCH_LIMIT = 10
SEARCH_CONVERSIONS = {
                'city':set(['place','district']),
                'town':set(['place']),
                'township':set(['place']),
                'village':set(['place']),
                'county':set(['county','parish','census_area','borough','region']),
                'parish':set(['county','parish','census_area','borough','region']),
                'census_area':set(['county','parish','census_area','borough','region']),
                'borough':set(['county','parish','census_area','borough','region']),
                'region':set(['county','parish','census_area','borough','region']),
                'state':set(['state','territory','district']),
                'territory':set(['state','territory','district']),
                'council':set(['council_district','commissioner_district']),
                'commissioner':set(['council_district','commissioner_district']),
                'court':set(['chancery_court','superior_court','supreme_court','court_of_appeals','district_court','circuit_court','constable_districts']),
                'school':set(['school_board']),
                'ward':set(['anc','ward','precinct']),
                'anc':set(['anc','ward','precinct']),
                'precinct':set(['anc','ward','precinct']),
                'country':set(['country']),
                'cd':set(['cd']),
                'sldl':set(['sldl']),
                'sldu':set(['sldu'])}
                
# Old unnecessarily fancy code, kept if we decide to revert to a recursive
# matched model later
"""
def create_ocdid_dict(list_vals,ocd_dict):
    val = list_vals.pop()
    if not list_vals:
        d_type,d_val = val.split(':')
        if d_type not in ocd_dict:
            ocd_dict[d_type] = []
        ocd_dict[d_type].append(d_val)
        return
    if val not in ocd_dict:
        ocd_dict[val] = {}
    create_ocdid_dict(list_vals,ocd_dict[val])
"""

def is_ocdid(ocdid):
    """Check whether given ocdid is contained in the official ocdid list

    Keyword arguments:
    ocdid -- ocdid value to check if exists in the official ocdid list

    Returns:
    True -- ocdid exists
    False -- ocdid not found (could be candidate for new ocdid)

    """
    if ocdid in ocdid_set:
        return True
    else:
        return False

def match_name(ocdid_prefix,dist_type,dist_name):
    """Given a district name, returns closest ocdid match in given district

    Keyword arguments:
    ocdid_prefix -- ocdid section up to type value, must exist in ocdids
    dist_type -- district type value, must exist in ocdids[ocdid_prefix]
    dist_name -- district name to attempt match

    Returns:
    ocdid,ratio -- if match found, returns valid ocdid and name match ratio
    None,-1 -- if match not found, returns None for ocdid and -1 match ratio

    """
    # from list of districts of a given type, find the closest match
    try:
        match = process.extractOne(dist_name,ocdids[ocdid_prefix][dist_type])
    except KeyError:
        print 'Invalid ocdid_prefix or dist_type provided'
        raise

    # if match fails, return empty values
    if not match:
        return None,-1
    id_val,ratio = match

    # format ocdid, check that it exists, return id value and match ratio
    ocdid = '{}/{}:{}'.format(ocdid_prefix,dist_type,id_val)
    if is_ocdid(ocdid):
        return ocdid,ratio
    else:
        return None,-1

def match_type(ocdid_prefix,dist_type,dist_count):
    """Given a district type and count, returns official ocdid district type

    Keyword arguments:
    ocdid_prefix -- ocdid section up to type value, must exist in ocdids
    dist_type -- district type value, suggested types are: park, ward, school,
                     education, commission, council, district (generic)
    dist_count -- count of districts of given type in specific geography

    Returns:
    key -- if match found, returns valid ocdid and name match ratio
    'No match' -- if not match found, returns None for ocdid and -1 match ratio

    """
    # default initial values for key, district length difference, and
    # district type ratio
    key = ''
    diff_len = 1000
    type_ratio = 0

    for k,v in ocdids[ocdid_prefix].iteritems():
        #special case for school based districts, must be explicitly requested
        if 'school' in k and dist_type != 'school':
            continue
        # matches to district closest in count, using district type as a
        # secondary matching trait, 'district' is the generic type
        new_diff_len = abs(len(v)-dist_count)
        new_type_ratio = fuzz.ratio(k,dist_type)
        if new_diff_len < diff_len:
            diff_len = new_diff_len
            key = k
            type_ratio = new_type_ratio
        elif new_diff_len == diff_len and dist_type != 'district' and new_type_ratio > type_ratio:
            key = k
            type_ratio = new_type_ratio

    # district length difference must be less than 5% for a valid match
    if diff_len == 0:
        return key
    elif float(diff_len)/dist_count < .05:
        ocd_count = len(ocdids[ocdid_prefix][key])
        if dist_count > ocd_count:
            print 'Extra provided districts:{}'.format(dist_count-ocd_count)
        else:
            print 'Extra official districts:{}'.format(ocd_count-dist_count)
        return key
    else:
        return 'No match'

def name_search(name):
    """Given a district name, searches for all matching ocdids
        
    ***SLOW MATCHING*** 
    searches everything, use a more limiting search for quicker results

    Keyword arguments:
    name -- district name to search for

    Returns:
    match_list[:MATCH_LIMIT] -- a list of the top 'MATCH_LIMIT' matches that
                                    are greater than 'MATCH_RATIO'

    """
    match_list = []
    
    for prefix,district in ocdids.iteritems():
        for dist_type,dist_names in district.iteritems():
            # pull the closest match from each set of districts, adds to
            # match_list if > MATCH_RATIO
            match_vals = process.extractOne(name,dist_names)
            if match_vals and match_vals[1] > MATCH_RATIO:
                match_list.append((match_vals[1],'{}/{}:{}'.format(prefix,dist_type,match_vals[0])))
    
    # sorts and returns top MATCH_LIMIT matches
    match_list = sorted(match_list,key=itemgetter(0))
    match_list.reverse()
    return match_list[:MATCH_LIMIT]

def type_name_search(type_val,name):
    """Given a district name and type, searches for all matching ocdids

    Keyword arguments:
    type_val -- district type to search for, valid types: anc, cd, county,
                    council, village, borough, ward, township, city, court,
                    parish, state, territory, sldu, commissioner, sldl,
                    precinct, town, school, country, region, census_area
    name -- district name to search for

    Returns:
    match_list[:MATCH_LIMIT] -- a list of the top 'MATCH_LIMIT' matches that
                                    are greater than 'MATCH_RATIO' 

    """
    match_list = []

    # if type_val is standard, use the set of valid district type matches
    # otherwise accept 'all' matches
    if type_val in SEARCH_CONVERSIONS:
        valid_dists = SEARCH_CONVERSIONS[type_val]
    else:
        valid_dists == 'all'

    for prefix,district in ocdids.iteritems():
        for dist_type,dist_names in district.iteritems():
            # pull the closest match from matching sets of districts, adds to
            # match_list if > MATCH_RATIO
            if valid_dists == 'all' or dist_type in valid_dists:
                match_vals = process.extractOne(name,dist_names)
                if match_vals and match_vals[1] > MATCH_RATIO:
                    match_list.append((match_vals[1],'{}/{}:{}'.format(prefix,dist_type,match_vals[0])))

    # sorts and returns top MATCH_LIMIT matches
    match_list = sorted(match_list,key=itemgetter(0))
    match_list.reverse()
    return match_list[:MATCH_LIMIT]


def print_subdistrict_data(ocdid_prefix):
    """Given a district name, returns closest ocdid match in given district

    Keyword arguments:
    ocdid_prefix -- district name to attempt match

    """
    print ocdid_prefix
    for k,v in ocdids[ocdid_prefix].iteritems():
        print '  - {}:{}'.format(k,v)

""" If a url is provided, use 'requests' to obtain ocdid data
        otherwise, read from file system """
if 'http' in OCDID_DATA:
    r = requests.get(OCDID_DATA)
else:
    f = open(OCDID_DATA,'r')
    r = f.read()

""" Generate a set of only ocdid data with empty values removed """
ocdid_set = {line.split(',')[0] for line in r.text.split('\n') if line != ''}
if '' in ocdid_set:
    ocdid_set.discard('')
ocdids = {}

""" Create a dictionary of ocdid data in the format:
        {
            ocdid_prefix:
            {
                district_type:
                    [name_1,name_2,etc.]
            }
        } 
"""
for ocdid in ocdid_set:
    prefix_div = ocdid.rfind('/')
    ocdid_prefix = ocdid[:prefix_div]
    type_val,name = ocdid[prefix_div+1:].split(':')
    if ocdid_prefix not in ocdids:
        ocdids[ocdid_prefix] = {}
    if type_val not in ocdids[ocdid_prefix]:
        ocdids[ocdid_prefix][type_val] = []
    ocdids[ocdid_prefix][type_val].append(name)
