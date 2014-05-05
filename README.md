# Open Civic Data Division Identifiers (OCD-ID)

The goal of this project is to assign somewhat predictable and globally unique identifiers to political divisions.

## Definitions

* **Division** - A political geography such as a state, county, or congressional district, which may have multiple **boundaries** over its lifetime.  Types of divisions include, among others:
   * Governmental jurisdiction - A division that a government has jurisdiction over.  (e.g. North Carolina)
   * Political district - A division that elects a representative to a legislature.  (e.g. North Carolina Congressional District 4)
   * Service zone - An area to which a government provides a service.  (e.g. Washington DC Police District 105)
* **Boundary** - An geographical boundary, defined by a shapefile or a sequence of address ranges.  (e.g. NC Congressional District 10 for the 113th Congress)

This document describes an identifier scheme for assigning globally unique identifiers to divisions.  It does *not* describe any scheme for boundaries.

## Identifier scheme

Identifiers respect the format `ocd-division/country:<country_code>[/<type>:<type_id>]+`

* **country_code** - An [ISO-3166-1 alpha-2 code](http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2).
* **type** - The type of boundary.  (e.g. `country`, `state`, `town`, `city`, `cd`, `sldl`, `sldu`)
  * Valid characters are lowercase UTF-8 letters, dash (-), and underscore (\_).
  * Use existing types where possible.
* **type_id** - An identifier that is locally unique to its scope.
  * Valid characters are lowercase UTF-8 letters, numerals (0-9), period (.), hyphen (-), underscore (\_), and tilde (~).  These characters match the unreserved characters in a URI [RFC 3986 section 2.3](http://www.rfc-editor.org/rfc/rfc3986.txt).
  * Characters must be converted to UTF-8.
  * Uppercase characters must be converted to lowercase.
  * Spaces must be converted to underscores.
  * All invalid characters must be converted to tildes (~).
  * Leading zeros should be removed unless doing so changes the meaning of the identifier.

## Assignment

* An identifier should not attempt to capture the full hierarchy of the division, but enough to be uniquely identify it.  (e.g. If there are school districts at the county and city level, county and city are important disambiguators and should be included in the identifier)
* If possible, all divisions of the same type should be defined at the same time; for example, all state divisions should be defined at once.  Similarly, all cities in North Carolina should be defined at once, to avoid adopting a scheme that produces collisions.
* When selecting a `type_id`, preference should be given to existing, common identifiers, like postal abbreviations for US states.  Numeric identifiers (such as US county FIPS codes) should be avoided if textual names are clear and unambiguous; however, numeric identifiers may be appended to disambiguate a `type_id`.
* The set of types within each country should not grow unnecessarily.  Each country maintainer should publish a list of types for easy reference.  The addition of a new type must be justified.
    * For example: In the US, there are no clear-cut differences between cities, towns, villages, etc. Therefore, the Census-recommended term `place` is used as the type of cities, etc.

## Repository layout

* The `identifiers` directory contains CSV files assigning all OCD identifiers:
  * A single CSV file per country, in the format `country-<country_code>.csv`.
    * The URLs of these files are stable.
  * An optional directory per country, in the format `country-<country_code>`:
    * A file hierarchy, in which CSV files describe parts of the top-level country CSV file.
      * The URLs of these files are *not* stable.
* The `corrections` directory contains CSV files that map incorrect OCD identifiers to correct OCD identifiers.  Common errors include missing diacritics, differences in hyphenation and word order, use of Roman numerals, etc.

## CSV file format

* A CSV file must have two or more columns.  The first column must contain OCD identifiers.

### Identifiers

* If a CSV file has no header row, the CSV is assumed to have two columns with the headers `id` and `name`.
* If a CSV file has a header row, the first column name must be `id`.
* Column names with special meaning are:
  * **name** - The name of the division.
  * **sameAs** - An OCD identifier which identifies the same division as this identifier.  The row corresponding to the identifier in this column must have a blank value in its `sameAs` column, i.e. there must be no daisy-chaining or circular references.
  * **sameAsNote** - A note describing how or why the division has multiple identifiers.
  * **validThrough** - The date on which the division is no longer valid, in the format `YYYY`, `YYYY-MM` or `YYYY-MM-DD`.  A division may become invalid if, for example, a political district is abolished.
* Reserved column names are:
  * **validFrom** - The date on which a division becomes valid, in the format `YYYY`, `YYYY-MM` or `YYYY-MM-DD`.  A division may become valid if, for example, a political district is created.
* There are no restrictions on other columns.
* An effort should be made to use descriptive CSV filenames.

### Corrections

* A CSV file must have a header row of `incorrectId,id,note`.
* **incorrectId** - An incorrect OCD identifier, i.e. an OCD identifier that was never valid.
* **id** - The corrected OCD identifier.
* **note** - Free-text describing the error, e.g. "missing diacritics".

## Semantics

* All OCD identifiers are first-class.  However, if it is necessary for a system for choose a "primary" or "preferred" identifier for a division, it should use those identifiers with an empty `sameAs` column.
* The `sameAs` relationship is symmetric and transitive.  The `sameAs` relationship is not true for all time; it is only true in the present.

## Governance

This project has an informal governance structure, led by the project's early contributors and informed by the [Open Civic Data Google Group](https://groups.google.com/forum/#!forum/open-civic-data).  Responsibility for a country's identifiers may be assigned to organizations.

## Examples

* United States
  * ocd-division/country:us
* North Carolina
  * ocd-division/country:us/state:nc
* North Carolina 2nd Congressional District
  * ocd-division/country:us/state:nc/cd:2
* North Carolina State Lower Legislative District 1
  * ocd-division/country:us/state:nc/sldl:1
* Wake County, North Carolina
  * ocd-division/country:us/state:nc/county:wake
* Cary, North Carolina  (note that despite being within Wake County this is not indicated due to not being an identifying feature)
  * ocd-division/country:us/state:nc/place:cary
* Kildaire Farms Homeowners Association, Cary, North Carolina
  * ocd-division/country:us/state:nc/place:cary/hoa:kildaire_farms
* Washington DC, Ward 8
  * ocd-division/country:us/district:dc/ward:8
* Washington DC, ANC 4A
  * ocd-division/country:us/district:dc/anc:4a
* Washington DC, ANC 4A, section 08  _note: this is a strict subset of the ANC for purposes of representation_
  * ocd-division/country:us/district:dc/anc:4a/section:8
* New York City, City Council District 36 (happens to be in Brooklyn- but not significant to include in id)
  * ocd-division/country:us/state:ny/place:new_york/council_district:36
* Canadian Federal Electoral District 13004 aka [Fundy Royal](http://en.wikipedia.org/wiki/Fundy_Royal) (known as Royal from 1914-1966, Fundy-Royal from 1966-2003, and Fundy from 2003-2004- hence the use of a numeric identifier assigned by the government)
  * ocd-division/country:ca/ed:13004
