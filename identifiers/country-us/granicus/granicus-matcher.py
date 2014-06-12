#!/usr/bin/env python
import sys
import time
import requests


ENDPOINT = "http://hippalus.granicuslabs.com/v2/jurisdictions.json"

def iterfeed(page=None):
    if page is None:
        page = 1
    try:
        sys.stderr.write("Getting page %s\n" % (page))
        sys.stderr.flush()
        resp = requests.get("%s?page=%s" % (ENDPOINT, page))
    except requests.exceptions.ConnectionError:
        sys.stderr.write("   [ connection failure ]\n")
        sys.stderr.flush()
        yield from iterfeed(page=page)
        return

    data = resp.json()
    total = data['total_entries']
    per_page = data['per_page']
    last_page = total / per_page
    for result in data['results']:
        yield result

    if page < last_page:
        time.sleep(4)
        yield from iterfeed(page=(page + 1))


print("id,freebase,granicus_id")
for el in iterfeed():
    ocd_id = None
    freebase_id = None
    for identifier in el['identifiers']:
        if identifier['scheme'] == 'OCD':
            ocd_id = identifier['identifier']
        if identifier['scheme'] == 'Freebase':
            freebase_id = identifier['identifier']

    try:
        assert ocd_id is not None
    except AssertionError:
        print(el)
        raise

    print('"%s","%s","%s"' % (
        ocd_id,
        freebase_id if freebase_id else "",
        el['id']
    ))
    sys.stdout.flush()
