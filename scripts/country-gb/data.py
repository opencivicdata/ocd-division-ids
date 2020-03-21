# The UK Parliament (House of Commons) has members at constituency level
# in England, Wales, Scotland and Northern Ireland
pcon = {
    # data from: https://geoportal.statistics.gov.uk/datasets/westminster-parliamentary-constituencies-december-2018-uk-bfe
    'url': 'https://opendata.arcgis.com/datasets/78690ecedd5545c097637132d8c9e3b3_0.csv',
    'gss_column': 'pcon18cd',
    'name_column': 'pcon18nm',
    'prefix': 'pcon',
    'filename': 'uk_parliament_constituencies.csv',
    'use_nation_clause': False,
}


# The Scottish Parliament has members at both constituency and regional levels
spc = {
    # data from: http://geoportal.statistics.gov.uk/datasets/scottish-parliamentary-constituencies-may-2016-full-extent-boundaries-in-scotland
    'url': 'https://opendata.arcgis.com/datasets/00436d85fa664f0fb7dce4a1aff83f27_1.csv',
    'gss_column': 'spc16cd',
    'name_column': 'spc16nm',
    'prefix': 'spc',
    'filename': 'scottish_parliament_constituencies.csv',
    'use_nation_clause': True,
}
spr = {
    # data from: http://geoportal.statistics.gov.uk/datasets/scottish-parliamentary-regions-may-2016-full-extent-boundaries-in-scotland
    'url': 'https://opendata.arcgis.com/datasets/c890fc7b1ad14311bb71660ec6524c9e_1.csv',
    'gss_column': 'spr16cd',
    'name_column': 'spr16nm',
    'prefix': 'spr',
    'filename': 'scottish_parliament_regions.csv',
    'use_nation_clause': True,
}


# The National Assembly for Wales has members
# at both constituency and regional levels
nawc = {
    # data from: http://geoportal.statistics.gov.uk/datasets/national-assembly-for-wales-constituencies-december-2017-wa-bfe
    'url': 'https://opendata.arcgis.com/datasets/7a4dc40d6c9e4abf8d2fa3b369395d93_1.csv',
    'gss_column': 'nawc17cd',
    'name_column': 'nawc17nm',
    'prefix': 'nawc',
    'filename': 'naw_constituencies.csv',
    'use_nation_clause': True,
}
nawr = {
    # data from: http://geoportal.statistics.gov.uk/datasets/national-assembly-for-wales-electoral-regions-december-2017-wa-bfe
    'url': 'https://opendata.arcgis.com/datasets/d10026914aa64c4cadcfafad73f81bf7_1.csv',
    'gss_column': 'nawer17cd',
    'name_column': 'nawer17nm',
    'prefix': 'nawr',
    'filename': 'naw_regions.csv',
    'use_nation_clause': True,
}


# Combined Authorities have a directly elected regional Mayor
cauth = {
    # data from: http://geoportal.statistics.gov.uk/datasets/combined-authorities-march-2017-full-extent-boundaries-in-england
    'url': 'https://opendata.arcgis.com/datasets/89f12fc184d045a1a7ca9dd14fb4df3e_1.csv',
    'gss_column': 'cauth17cd',
    'name_column': 'cauth17nm',
    'prefix': 'cauth',
    'filename': 'combined_authorities.csv',
    'use_nation_clause': False,
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
    'use_nation_clause': False,
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
