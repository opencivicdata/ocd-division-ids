# Open Civic Data Divisions: Canada

## Usage

    ./scripts/country-ca/run-all.sh

## Identifiers and mappings

### Types

* `province`: province
* `territory`: territory
* `ed`: electoral district
* `cd`: census division
* `csd`: census subdivision
* `arrondissement`: municipal borough
* `borough`: municipal borough
* `district`: municipal district
* `division`: municipal division
* `ward`: municipal ward

### Type IDs

* At the provincial level, MB, NL and SK use textual type IDs for electoral districts. All other jurisdictions use numeric type IDs.

### Mappings

* `country-ca-abbr`: English Census or local abbreviations
* `country-ca-abbr-fr`: French Census or local abbreviations
* `country-ca-fr`: French names
* `country-ca-numeric`: Numeric local identifiers
* `country-ca-sgc`: Standard Geographical Classification (SGC) codes
* `country-ca-subdivisions`: Whether the division has children
* `country-ca-types`: Census subdivision types
* `country-ca-urls`: Official website URLs

## Writing a scraper

### Scraper checklist

* Does the jurisdiction use identifiers?
* Does the jurisdiction translate names?

### Data source selection guidelines

1. Prefer an official government source.
  1. For electoral districts, prefer election officials to legislatures.
1. Prefer the source with correct names.
1. Prefer the source with correct formatting (dashes).
1. Prefer the source that is easier to scrape.

## Changes over time

The Standard Geographical Classification is an official publication of Statistics Canada since 1974.

### Provinces and territories

* Effective October 20, 2008, [Yukon Territory became Yukon](http://www.statcan.gc.ca/subjects-sujets/standard-norme/sgc-cgt/notice-avis/sgc-cgt-01-eng.htm).
* Effective October 21, 2002, [NF became NL](http://www.statcan.gc.ca/subjects-sujets/standard-norme/sgc-cgt/2006/2006-intro-fin-eng.htm).
* Effective March 21, 2003, [Nfld.Lab. became N.L.](http://www.statcan.gc.ca/subjects-sujets/standard-norme/sgc-cgt/2001/2001-supp2-eng.htm).
* On April 1, 1999, [Nunavut came into being officially as a Territory of Canada](http://www.statcan.gc.ca/subjects-sujets/standard-norme/sgc-cgt/1996/1996-supp-eng.htm).
