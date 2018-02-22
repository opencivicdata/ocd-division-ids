# country-uk

The UK mapping and place naming agency is called the [Ordnance Survey](https://www.ordnancesurvey.co.uk/). They release much of thier data with open licenses as shapefiles, including a set of all electoral jurisdictions available [here](https://www.ordnancesurvey.co.uk/opendatadownload/products.html#BDLINE) and a [named places](https://www.ordnancesurvey.co.uk/opendatadownload/products.html#OPNAME) dataset full of towns and cities.

The [Ordnance Survey Boundary Types](https://www.ordnancesurvey.co.uk/business-and-government/help-and-support/web-services/administrative-boundaries.html) page and wiki articles [Administrative Geography of the United Kingdom](https://en.wikipedia.org/wiki/Administrative_geography_of_the_United_Kingdom) and [Subdivisions of England](https://en.wikipedia.org/wiki/Subdivisions_of_England) are helpful.

The electoral data contains the following sub types, for additional information see the [Ordnance Survey administrative geography and civil voting area ontology](http://data.ordnancesurvey.co.uk/ontology/admingeo/).

The short codes (ced, cpc, etc) for types were chosen to align with Ordnance survey. In cases where I have added new types (wales) I tried to be more verbose. Welsh community codes prefixed to avoid confusion with the U.S. usage of the word 'community' for a city.

When available in the data, the Ordnance Survey ID, dbpedia, and geonames links have been preserved.

## Electoral Areas
|Code|Name|Description|
|---|---|---|
|ced|County Electoral Division|   |
|cpc|Council Parish|   |
|cty|County|UK Counties, with a different identifier to keep them distinct from US counties|
|diw|District Ward|   |
|dis|District|   |
|eur|European Regions|    |
|gla|Greater London Authority| |
|lac|Greater London Authority Assembly Constituency|   |
|lbo|London Borough|   |
|lbw|London Borough Ward|   |
|mtd|Metropolitan District|   |
|mtw|Metropolitan District Ward|   |
|spe|Scottish Parliament  Electoral Region| |
|spc|Scottish Parliament Contituency|   |
|uta|Unitary Authority|   |
|ute|[Unitary Electoral Division](http://data.ordnancesurvey.co.uk/ontology/admingeo/UnitaryAuthorityElectoralDivision)|   |
|utw|Unitary District Ward| |
|wac|Welsh Assembly Constituency|   |
|wae|Welsh Assembly Electoral Region|    |
|wmc|Westminster Constituency|*House of commons parliamentary constituencies*, these are the national 'lower house' divisions|
|welsh_community|Welsh Community Electoral Areas|(Wales renames things confusingly)[https://en.wikipedia.org/wiki/Wards_and_electoral_divisions_of_the_United_Kingdom#Wales] but their 'communities' are equivalent to Council Parishes in the UK.|
|welsh_community_ward|Welsh Community Ward|Child divisions of Welsh communities|
|welsh_noncommunity_ward|Welsh Non-Community Ward|Child divisions of Welsh communities|
|ceremonial_county|[Ceremonial County](https://en.wikipedia.org/wiki/Ceremonial_counties_of_England)|Lord lieutenancies|

## Named Places
|Code|Name|Description|
|---|---|---|
|city||From the Open Names dataset|
|hamlet||From the Open Names dataset|
|settlement||From the Open Names dataset - Renamed from 'other settlement'|
|suburban_area||From the Open Names dataset|
|town||From the Open Names dataset|
|village||From the Open Names dataset|