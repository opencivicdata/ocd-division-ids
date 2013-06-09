# Open Civic Data Divisions: Canada

## Usage

    ./scripts/country-ca/run-all.sh

## Types

* `province`: province
* `territory`: territory
* `ed`: electoral district
* `csd`: census subdivision

## Type IDs

* MB, NL and SK use textual type IDs for electoral districts. All other jurisdictions use numeric type IDs.

## Scraper checklist

* Does the jurisdiction use identifiers?
* Does the jurisdiction translate names?

## Data source selection guidelines

1. Prefer an official government source.
  1. For electoral districts, prefer election officials to legislatures.
1. Prefer the source with correct names.
1. Prefer the source with correct formatting (dashes).
1. Prefer the source that is easier to scrape.
