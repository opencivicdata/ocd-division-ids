# U.S. OCD Division Identifier Quirks

This page details some of the quirks of poltical division in the United States and will help you navigate U.S. identifiers. You should have already read [the overall project's documention](https://github.com/opencivicdata/ocd-division-ids/blob/master/README.md).

There is only one rule about U.S. political geography: “There are no hard and fast rules regarding U.S. political geography.” (h/t Jonathan Tomer)

With that in mind, below are some interesting OCD Identifiers that might not seem obvious at first. Also, a Google-spreadsheet-based [validator](https://docs.google.com/spreadsheet/ccc?key=0ApxTEufS6-DndE16N0J3d19zUHVMOVFsYU9vRHF3S2c&usp=sharing) is available to check all of your identifiers (especially for those you are unsure about); the spreadsheet also provides suggestions for unmatched identifiers.

## state

* The District of Columbia is: cd-division/country:us/district:dc
* Territories also are included:
	* Example (American Samoa): ocd-division/country:us/territory:as

## county

* Residents of DC (or the territories) do not have a county.
* Alaska has borough and census_area types
* Louisiana has parishes
* The residents of independent cities of Virignia do not have counties
	* **Important**: Some independent cities have the same name as counties. Care must be taken
* Similarly Maryland, Missouri and Nevada each has one independent city
	
## place

* Drop "city", "township", "borough" (etc) from the name of a place type unless the word city is in the census’s [place gazetteer file](http://www.census.gov/geo/maps-data/data/docs/gazetteer/Gaz_places_national.zip). Two examples:
	* ocd-division/country:us/state:mo/place:[jefferson_city](http://en.wikipedia.org/wiki/Jefferson_City,_Missouri)
	* ocd-division/country:us/state:mo/place:[jennings](http://en.wikipedia.org/wiki/Jennings,_MO)
* Sometimes, for disambiguity, place reisdes under county. Example:
	* ocd-division/country:us/state:pa/county:adams/place:liberty
* The following are [consolidated city-counties](https://en.wikipedia.org/wiki/Consolidated_city-county) with coterminous boundaries. Only one identifier (the county: identifier) is included in the canonical list to avoid confusion. To further help users, an [exceptions file](https://github.com/opencivicdata/ocd-division-ids/blob/master/identifiers/country-us/README.md) lists all of the identifiers that one might expect to exist, but do not.
	* Anchorage, AK
	* Juneau, AK
	* Sitka, AK
	* Wrangell, AK
	* San Francisco, CA
	* Broomfield, CO
	* Denver, CO
	* Columbus, GA (Muscogee County)
	* Lexington, KY (Fayette County)
	* New Orleans, LA
	* Nantucket, MA
	* Anaconda, MT (Silver Bow County)
	* Lynchburg, TN (Moore County)
	* **Not** on this list: Cusetta, GA is not coterminous with its county despite having the same government
	* **Not** on this list: Georgetown, GA is not coterminous with its county despite having the same government
	* **Not** on this list: Philadelphia, PA is not on this list because the county and city play different roles in governance.
	* **Not** on this list: Butte-Silver Bow County, MT is not on this list because they are not coterminous. The census-recognized town of [Walkerville](https://en.wikipedia.org/wiki/Walkerville,_Montana) is also in the county
* The [exceptions file](https://github.com/opencivicdata/ocd-division-ids/blob/master/identifiers/country-us/exceptions.txt), which is a superset of the above list, has three fields in the following order:
	* Non-canonical identifier (i.e., the one you should **not** use)
	* Associated canonical identifier -- use this one
	* Note for why this association exists
* The [whitelist file](https://github.com/opencivicdata/ocd-division-ids/blob/master/identifiers/country-us/census_whitelist.txt) picks up places that the Census scraper misses. It has two fields:
  * Canonical identifier
  * Note for why the census scraper misses this jurisdiction

	
## cd

* At-large congressional districts (AK, DE, MT, ND, SD, VT, WY) do not have division identifiers because they are coterminous with the state.
* The [exceptions file](https://github.com/opencivicdata/ocd-division-ids/blob/master/identifiers/country-us/README.md) includes this idiosyncracy of U.S. congressional districts.

## sldl (State Legislature distict -- lower)

* Remember to keep all letter lowercase. Example:
	* ocd-division/country:us/state:md/sldl:12b
* Nebraska has no lower house
* The states of MA, VT, NH have interesting names district names, rather than numbers. Use the [naming convention](https://github.com/opencivicdata/ocd-division-ids/blob/master/README.md).

## sldu (State Legislature distict -- upper)

* The states of MA and VT have interesting names for their upper house districts. Use the [naming convention](https://github.com/opencivicdata/ocd-division-ids/blob/master/README.md).

## council_district

* For ease, all types of local councils that have custom districts -- whether they are called city council, board of supervisors, town council, or common council -- use the type council_district. Examples:
	* ocd-division/country:us/state:md/place:baltimore/council_district:1
	* ocd-division/country:us/state:va/county:fairfax/council_district:providence
* **Sometimes the council districts are not custom district** -- a city might reuse wards, for instance. In these cases, to avoid redundancy, we only put ward in the repository.
* Occasionally (and namely, for Indiana counties), a single governmental entity (e.g., [Lake County Indidana](http://www.lakecountyin.org)) will have multiple bodies that use different districts. In these cases, we strive to use the "council_district" for the governmental body with "council" in its name and use a custom type for the other body (e.g., [commissioner district](http://www.lakecountyin.org/portal/media-type/html/group/commissioners/page/default)).

## ward

* Sometimes wards (and council_districts) will be labeled using roman numerals (i, ii, iii, iv, etc). These are converted to arabic numerals (1, 2, 3, 4, etc).
	* These transformations are also in the [exceptions file](https://github.com/opencivicdata/ocd-division-ids/blob/master/identifiers/country-us/README.md)

## region

* The Oregon Metro council is in the repository:
	* ocd-division/country:us/state:or/region:oregon_metro
* The Metro council also has districts
	* ocd-division/country:us/state:or/region:oregon_metro/council_district:1

## precinct

* Precincts are slowly being added (as of January 2014). Notes:
  * If a precinct (i.e., voting tabulation district, election district) is called a "ward" generally the ward type is used. Otherwise, the precinct type is used.
  * Often, precincts will have both a unique county or state ID as well as a descriptor. In this case, the number will go first (no zero padding), then a hyphen ("-"), then the descriptor. See parts of [Idaho](https://github.com/opencivicdata/ocd-division-ids/blob/master/identifiers/country-us/state-id-precincts.csv).
  * Other times, a descriptor will include a number. For instance, Canton County might have the precincts Tenley 1, Tenley 2, Lincoln 1, and Lincoln 2. In this case, only a space (which is converted to an underscore) separates the text and the number. See parts of [Idaho](https://github.com/opencivicdata/ocd-division-ids/blob/master/identifiers/country-us/state-id-precincts.csv) and [Vermont](https://github.com/opencivicdata/ocd-division-ids/blob/master/identifiers/country-us/state-vt-precincts.csv).

