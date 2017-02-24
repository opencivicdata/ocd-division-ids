# Open Civic Data Divisions: Canada

## Maintenance

    ./scripts/country-ca/run-all.sh

## Identifiers and mappings

### Types

* `province`: province
* `territory`: territory
* `ed`: electoral district
* `cd`: census division
* `csd`: census subdivision
* `borough`: municipal borough
* `district`: municipal district
* `division`: municipal division
* `ward`: municipal ward

### Type IDs

* At the provincial level, MB, NL and SK use textual type IDs for electoral districts. All other jurisdictions use numeric type IDs.

### Column headers

* `abbreviation`: English Census or local abbreviations
* `abbreviation_fr`: French Census or local abbreviations
* `classification`: Census subdivision types
* `data_catalog`: Official data catalog URL
* `has_children`: Whether the division has children
* `name_fr`: French names
* `number`: Numeric local identifiers
* `organization_name`: Municipal corporation names
* `parent_id`: Upper tier municipality OCD-ID
* `posts_count`: Number of posts in the municipal corporation
* `sgc`: Standard Geographical Classification (SGC) codes
* `url`: Official website URLs

## Writing a scraper

### Scraper checklist

* Does the jurisdiction use identifiers?
* Does the jurisdiction translate names?

### Data source selection guidelines

1. Prefer an official government source. For electoral districts, prefer election officials to legislatures.
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

## Uses

* [represent-canada-data](https://github.com/opennorth/represent-canada-data/blob/master/tasks.py)
  * `abbreviation`: To map province and territory abbreviations to names
  * `classification`: To determine an appropriate subdivision label
  * `has_children`: To determine whether a shapefile must be requested for a division
  * `organization_name`: To set an appropriate authority for a shapefile
  * `sgc`: To retrieve an identifier from an SGC code
  * `url`: To provide a URL from which to request a shapefile for a division
* [scrapers-ca](https://github.com/opencivicdata/scrapers-ca/blob/master/tasks.py)
  * `parent_id`: To determine the administrative subdivisions of Census divisions
  * `classification`: To determine an appropriate jurisdiction name
  * `sgc`: To retrieve an identifier from an SGC code
  * `url`: To provide a URL for the jurisdiction
  * `posts_count`: To create posts automatically
* [scrapers-ca-ruby](https://github.com/opennorth/scrapers-ca-ruby/blob/master/ca_qc_montreal/posts.rb)
  * `number`: To map numeric borough identifiers to names
* [comingelections.com](https://github.com/opennorth/comingelections/blob/master/lib/tasks/scrape.rake)
