#!/usr/bin/env python3
import os
import sys
import csv
import fnmatch
import argparse
import collections
from compile import validate_id
from compile import abort


# Explicitly disallow python 2.x
if sys.version_info < (3, 0):
    sys.stdout.write("Python 2.x not supported.\n")
    sys.exit(1)

def open_csv(filename):
    """ return a DictReader iterable regardless of input CSV type """
    fh = open(filename)
    print('processing', filename)
    first_row = next(csv.reader(fh))
    fh.seek(0)
    return csv.DictReader(fh)

def main():
    parser = argparse.ArgumentParser(description='combine correction CSV files into one')
    parser.add_argument('country', type=str, default=None, help='country to compile')
    args = parser.parse_args()
    country = args.country.lower()

    corrections = collections.defaultdict(dict)
    canonical_ids = set()
    required_fields = ['incorrectId', 'id', 'note']

    repo_file = 'identifiers/country-{}.csv'.format(country)

    # Reads in all ocd division ids from compiles country file
    #  including those that are aliased to others,
    #  thus allowing corrected ids to point to aliased ocd division ids
    repocsv = open_csv(repo_file)
    print('reading country file', repo_file)
    for row in repocsv:
        canonical_ids.add(row['id'])

    path = 'corrections/country-{}/'.format(country)
    filenames = [os.path.join(dirpath, f)
                 for dirpath, dirnames, files in os.walk(path)
                 for f in fnmatch.filter(files, '*.csv')]
    
    for filename in filenames:
        csvfile = open_csv(filename)
        
        #check required columns
        for k in required_fields:
            if k not in csvfile.fieldnames:
                abort('no {} column in {}: {}'.format(k, filename, e))                    

        for row in csvfile:

            id_ = row['id']
            incorrect_id = row['incorrectId']
            try:
                validate_id(id_)
            except ValueError as e:
                abort('invalid id {} in {}: {}'.format(id_, filename, e))


            if id_ in canonical_ids:
                if incorrect_id in corrections:
                    print('incorrectId {} in {} seen before: {}'.format(incorrect_id, filename, e))
                else:
                    corrections[incorrect_id] = row
            else:
                print('id {} in {} not present in country csv file: {}'.format(id_, filename, e))


    # write output file
    output_file = 'corrections/country-{}.csv'.format(country)
    print('writing', output_file)
    with open(output_file, 'w') as out:
        out = csv.DictWriter(out, fieldnames=['incorrectId','id','note'])
        out.writeheader()
        for incorrect_id, row in corrections.items():
            out.writerow(row)

if __name__ == '__main__':
    main()
