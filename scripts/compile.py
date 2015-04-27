#!/usr/bin/env python3
import re
import os
import sys
import csv
import glob
import fnmatch
import argparse
import datetime
import warnings
import collections


# Explicitly disallow python 2.x
if sys.version_info < (3, 0):
    sys.stdout.write("Python 2.x not supported.\n")
    sys.exit(1)


def validate_id(id_):
    id_regex = re.compile(r'^ocd-division/country:[a-z]{2}(/[^\W\d]+:[\w.~-]+)*$', re.U)
    if not (id_regex.match(id_) and id_.lower() == id_):
        raise ValueError('invalid id: ' + id_)

def validate_date(date_):
    formats = ['%Y-%m-%d', '%Y-%m', '%Y']
    for format in formats:
        try:
            datetime.datetime.strptime(date_, format)
            break
        except ValueError:
            pass
    else:
        raise ValueError('invalid date: ' + date_)


def abort(msg):
    """ print in red and exit """
    print('\033[91mERROR:', msg, '\033[0m')
    sys.exit(1)


def open_csv(filename):
    """ return a DictReader iterable regardless of input CSV type """
    fh = open(filename)
    first_row = next(csv.reader(fh))
    if 'ocd-division/country' in first_row[0]:
        if len(first_row) == 2:
            print('processing (legacy mode)', filename)
            warnings.warn('proceeding in legacy mode, please add column headers to file',
                          DeprecationWarning)
            fh.seek(0)
            return csv.DictReader(fh, ('id', 'name'))
        else:
            abort('No column headers detected in ' + filename)
    else:
        print('processing', filename)
        fh.seek(0)
        return csv.DictReader(fh)

FIELD_VALIDATORS = {
    'id': validate_id,
    'validThrough': validate_date,
}

COUNTRY_UNIQUE_FIELDS = {
    'us': ['census_geoid', 'census_geoid_12', 'census_geoid_14'],
    'ca': [
        'data_catalog',
        'sgc',
        # 'url' should probably be unique, but it is not.
        # The following may not prove to be globally unique:
        'abbreviation',
        'abbreviation_fr',
    ],
}

def main():
    parser = argparse.ArgumentParser(description='combine component CSV files into one')
    parser.add_argument('country', type=str, default=None, help='country to compile')
    args = parser.parse_args()
    country = args.country.lower()

    ids = collections.defaultdict(dict)
    sources = collections.defaultdict(list)
    records_with = collections.Counter()
    types = collections.Counter()
    same_as = {}
    all_keys = []
    missing_parents = set()

    path = 'identifiers/country-{}/'.format(country)
    filenames = [os.path.join(dirpath, f)
                 for dirpath, dirnames, files in os.walk(path)
                 for f in fnmatch.filter(files, '*.csv')]

    for filename in filenames:
        csvfile = open_csv(filename)
        if 'id' not in csvfile.fieldnames:
            abort('{} does not have id column')
        for field in csvfile.fieldnames:
            if field not in all_keys:
                all_keys.append(field)

        for row in csvfile:

            for field, validator in FIELD_VALIDATORS.items():
                val = row.get(field)
                if val:
                    try:
                        validator(val)
                    except ValueError as e:
                        abort('validation error in {}: {}'.format(filename, e))

            # check parents
            id_ = row['id']
            parent, endpiece = id_.rsplit('/', 1)
            if parent != 'ocd-division' and parent not in ids:
                missing_parents.add(parent)

            # count types
            type_ = endpiece.split(':')[0]
            types[type_] += 1

            # map sameAs
            if row.get('sameAs'):
                same_as[id_] = row['sameAs']

            # update record
            id_record = ids[id_]
            for key, val in row.items():
                # skip if value is blank
                if not val:
                    continue
                elif key not in id_record:
                    id_record[key] = val
                    records_with[key] += 1
                elif val and id_record[key] != val:
                    msg = 'mismatch for attribute {} on {}\n'.format(key, id_)
                    msg += 'was set to {} - got {} from {}\n'.format(id_record[key], val, filename)
                    msg += 'other sources:\n'
                    for source in sources[id_]:
                        msg += '   ' + source + '\n'
                    abort(msg)
            # add source
            sources[id_].append(filename)

    # process sameAs
    for dup_id, orig_id in same_as.items():
        if orig_id not in ids:
            abort('{0} is sameAs {1} which does not exist'.format(dup_id, orig_id))

        dup = ids[dup_id]
        orig = ids[orig_id]
        if orig.get('sameAs'):
            msg = 'sameAs chain: {0} -> {1} -> {2}'.format(
                dup_id, orig_id, orig['sameAs'])
            abort(msg)

        # copy name if it doesn't exist
        if not dup.get('name'):
            dup['name'] = orig['name']
            records_with['name'] += 1

    # data quality: parents
    missing_parents -= set(ids.keys())
    if missing_parents:
        msg = '{} unknown parents\n'.format(len(missing_parents))
        for parent in sorted(missing_parents):
            msg += '   ' + parent
        abort(msg)

    # data quality: required fields
    for field in ('name',):
        count_diff = records_with['id'] - records_with[field]
        if count_diff:
            msg = '{} records missing required field "{}"\n'.format(count_diff, field)
            for id_, row in ids.items():
                if field not in row:
                    msg += '   {} from {}\n'.format(id_, ', '.join(sources[id_]))
            abort(msg)

    # data quality: assert uniqueness of certain fields, ignoring missing values
    duplicate_values_found_in = {}
    unique_fields = ['id'] + COUNTRY_UNIQUE_FIELDS.get(country, [])
    for field in unique_fields:
        seen_values = set()
        duplicate_values = set()

        for row in ids.values():
            value = row.get(field, '')
            if value and value in seen_values:
                duplicate_values.add(value)
            seen_values.add(value)

        if duplicate_values:
            duplicate_values_found_in[field] = duplicate_values
    if duplicate_values_found_in:
        msg = "Duplicate values found in fields that should be unique!\n{}".format(duplicate_values_found_in)
        abort(msg)


    # print some statistics
    print('types')
    for type_, count in types.most_common():
        print('   {:<25} {:>10}'.format(type_, count))

    print('fields')
    for key, count in records_with.most_common():
        print('   {:<20} {:>10} {:>10.0%}'.format(key, count, count/records_with['id']))


    # set consistent field order [id, name, sameAs, validThrough] + sorted(the_rest)
    field_order = ['id', 'name', 'sameAs', 'sameAsNote', 'validThrough']
    for k in field_order[:]:
        if k in all_keys:
            all_keys.remove(k)
        else:
            field_order.remove(k)
    field_order += sorted(all_keys)

    # write output file
    output_file = 'identifiers/country-{}.csv'.format(country)
    print('writing', output_file)
    with open(output_file, 'w') as out:
        out = csv.DictWriter(out, fieldnames=field_order)
        out.writeheader()
        for id_, row in sorted(ids.items()):
            out.writerow(row)

if __name__ == '__main__':
    main()
