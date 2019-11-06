# The UK Parliament (House of Commons) has members at consitituency level
# in England, Wales, Scotland and Northern Ireland
pcon = {
    # data from: http://geoportal.statistics.gov.uk/datasets/westminster-parliamentary-constituencies-december-2017-full-extent-boundaries-in-the-uk-wgs84
    'url': 'https://opendata.arcgis.com/datasets/5c582cef61d04618928639dd17e4f896_1.csv',
    'gss_column': 'pcon17cd',
    'name_column': 'pcon17nm',
    'prefix': 'pcon',
    'filename': 'uk_parliament_consitituencies.csv'
}


# The Scottish Parliament has members at both consitituency and regional levels
spc = {
    # data from: http://geoportal.statistics.gov.uk/datasets/scottish-parliamentary-constituencies-may-2016-full-extent-boundaries-in-scotland
    'url': 'https://opendata.arcgis.com/datasets/00436d85fa664f0fb7dce4a1aff83f27_1.csv',
    'gss_column': 'spc16cd',
    'name_column': 'spc16nm',
    'prefix': 'spc',
    'filename': 'scottish_parliament_consitituencies.csv'
}
spr = {
    # data from: http://geoportal.statistics.gov.uk/datasets/scottish-parliamentary-regions-may-2016-full-extent-boundaries-in-scotland
    'url': 'https://opendata.arcgis.com/datasets/c890fc7b1ad14311bb71660ec6524c9e_1.csv',
    'gss_column': 'spr16cd',
    'name_column': 'spr16nm',
    'prefix': 'spr',
    'filename': 'scottish_parliament_regions.csv'
}


# The National Assembly for Wales has members
# at both consitituency and regional levels
nawc = {
    # data from: http://geoportal.statistics.gov.uk/datasets/national-assembly-for-wales-constituencies-december-2017-wa-bfe
    'url': 'https://opendata.arcgis.com/datasets/7a4dc40d6c9e4abf8d2fa3b369395d93_1.csv',
    'gss_column': 'nawc17cd',
    'name_column': 'nawc17nm',
    'prefix': 'nawc',
    'filename': 'naw_consitituencies.csv'
}
nawr = {
    # data from: http://geoportal.statistics.gov.uk/datasets/national-assembly-for-wales-electoral-regions-december-2017-wa-bfe
    'url': 'https://opendata.arcgis.com/datasets/d10026914aa64c4cadcfafad73f81bf7_1.csv',
    'gss_column': 'nawer17cd',
    'name_column': 'nawer17nm',
    'prefix': 'nawr',
    'filename': 'naw_regions.csv'
}


# Combined Authorities have a directly elected regional Mayor
cauth = {
    # data from: http://geoportal.statistics.gov.uk/datasets/combined-authorities-march-2017-full-extent-boundaries-in-england
    'url': 'https://opendata.arcgis.com/datasets/89f12fc184d045a1a7ca9dd14fb4df3e_1.csv',
    'gss_column': 'cauth17cd',
    'name_column': 'cauth17nm',
    'prefix': 'cauth',
    'filename': 'combined_authorities.csv'
}


# Most Police Force areas in England and Wales have a
# directly elected Police & Crime Commissioner
pfa = {
    # data from: http://geoportal.statistics.gov.uk/datasets/police-force-areas-december-2017-ew-bfe
    'url': 'https://opendata.arcgis.com/datasets/bb12117b37134a03874c55175cf7f4bc_1.csv',
    'gss_column': 'pfa17cd',
    'name_column': 'pfa17nm',
    'prefix': 'pfa',
    'filename': 'police_force_areas.csv',
    'exclude': [
        # These areas don't elect a Police & Crime Commissioner:
        'E23000001',  # Metropolitan Police
        'E23000005',  # Greater Manchester
        'E23000034',  # City of London
    ]
}


area_types = [
    pcon,
    spc,
    spr,
    nawc,
    nawr,
    cauth,
    pfa
]
