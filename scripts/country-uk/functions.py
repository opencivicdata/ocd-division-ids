import csv
import os
import re
import tempfile
import urllib.request


def get_csv_data(url):
    tmp = tempfile.NamedTemporaryFile()
    urllib.request.urlretrieve(url, tmp.name)
    # utf-8-sig is important here because CSV files from ONS
    # start with a Byte Order Mark character
    f = open(tmp.name, 'rt', encoding='utf-8-sig')
    reader = csv.DictReader(f, delimiter=',')
    return list(reader)


def write_csv(filename, csv_columns, dict_data):
    with open(filename, 'w') as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=csv_columns)
        writer.writeheader()
        for data in dict_data:
            writer.writerow(data)


def make_slug(name):
    slug = name.lower()

    # Make a couple of substitutions so we generate slightly nicer slugs:
    # Strip away any dots or commas
    slug = slug.replace('.', '').replace(',', '')

    """
    Replace '&' character with the word 'and'.

    It is quite a common pattern for UK Electoral divisions
    to have a name of the form 'This Place and That Place'
    e.g: 'Bath and North East Somerset'

    The word 'and' and the amphersand character are used inconsistently so
    this will sometimes be written 'Bath and North East Somerset'
    and sometimes 'Bath & North East Somerset'.

    For the purpose of generating nicer slugs which are easier to read,
    we'll standardise them all to use 'and' here.
    """
    slug = slug.replace('&', 'and')

    # Follow OCD slugging rules:
    slug = re.sub('\.? ', '_', slug)
    slug = re.sub('[^\w0-9~_.-]', '~', slug, re.UNICODE)
    return slug


def make_id(prefix, name):
    return 'ocd-division/country:uk/{prefix}:{slug}'.format(
        prefix=prefix,
        slug=make_slug(name)
    )


def make_csv_for_area_type(url, gss_column, name_column, prefix, filename, exclude=[]):
    in_rows = get_csv_data(url)
    out_rows = []

    for in_row in in_rows:
        out_row = {}
        out_row['id'] = make_id(prefix, in_row[name_column])
        out_row['name'] = in_row[name_column]
        out_row['gss_code'] = in_row[gss_column]
        if out_row['gss_code'] in exclude:
            continue
        out_rows.append(out_row)

    directory = os.path.abspath(
        os.path.join(os.path.dirname(__file__), '../../identifiers/country-uk')
    )
    if not os.path.exists(directory):
        os.makedirs(directory)

    write_csv(
        os.path.abspath(os.path.join(directory, filename)),
        ['id', 'name', 'gss_code'],
        out_rows
    )
