# Open Civic Data Divisions: United Kingdom

This folder lists the following divisions of the United Kingdom:

* Countries of the United Kingdom [ref](https://en.wikipedia.org/wiki/Countries_of_the_United_Kingdom).
* Regions of England [ref](https://simple.wikipedia.org/wiki/Regions_of_England).
* Constituencies of the UK Parliament [ref](https://en.wikipedia.org/wiki/Constituencies_of_the_Parliament_of_the_United_Kingdom).
* Constituencies and regions of the Scottish Parliament [ref](https://en.wikipedia.org/wiki/Scottish_Parliament_constituencies_and_regions).
* Constituencies and regions of the Senedd / Welsh Parliament, including the new 16-constituency boundaries effective May 2026 [ref](https://en.wikipedia.org/wiki/Senedd_constituencies_and_electoral_regions).
* UK-wide electoral wards [ref](https://en.wikipedia.org/wiki/Wards_and_electoral_divisions_of_the_United_Kingdom).
* English county electoral divisions [ref](https://en.wikipedia.org/wiki/County_electoral_division).

NI Assembly constituencies share boundaries with NI Westminster constituencies post the 2023 OSNI review and so reuse the corresponding `ed:` identifiers.

## Types

| Type | Path | Notes |
|---|---|---|
| `part` | `country:gb/part:<eng|sct|wls|nir>` | The four parts of the UK. |
| `region` | `country:gb/part:eng/region:<nuts1>` | NUTS1 regions of England. |
| `ed` | `country:gb/part:.../ed:<slug>` | Westminster (UK Parliament) constituencies. |
| `spc` | `country:gb/part:sct/spc:<slug>` | Scottish Parliament constituencies. |
| `spr` | `country:gb/part:sct/spr:<slug>` | Scottish Parliament regions. |
| `senc` | `country:gb/part:wls/senc:<slug>` | Senedd / Welsh Parliament constituencies. |
| `senr` | `country:gb/part:wls/senr:<slug>` | Senedd electoral regions (abolished from May 2026). |
| `ward` | `country:gb/part:.../ward:<gss>` | Electoral wards UK-wide. |
| `ced` | `country:gb/part:eng/ced:<gss>` | English county electoral divisions. |

Wards and county electoral divisions key on the canonical [GSS code](https://en.wikipedia.org/wiki/ONS_coding_system) instead of a name slug because UK ward names are not nationally unique (e.g. there are 21 wards named "Castle"). Constituencies and regions, by contrast, have unique names within each type.

The `senc` and `senr` prefixes follow the body's current name (Senedd / Welsh Parliament, post-2020). The earlier (never-merged) `country-uk` script used `nawc` / `nawr` from when the body was the National Assembly for Wales.

## Sources

* Westminster, Scottish Parliament, Senedd, ward, and CED boundaries: ONS [Open Geography Portal](https://geoportal.statistics.gov.uk/) -- Open Government Licence v3.0.
* Senedd post-May-2026 constituencies: [DataMapWales](https://datamap.gov.wales/layers/geonode:senedd_final_2026) (Welsh Government, OGL v3.0). The 16 constituencies use placeholder GSS codes of the form `W92000001`-`W92000016` until ONS publishes canonical codes; if those change, the `<gss>`-keyed identifiers in this folder will need a `sameAs` row.

## Updates

* 2023-07-01: After the 2023 Periodic Review of Westminster constituencies the Parliamentary Constituencies Order 2023 introduced a lot of changes for the next UK General Election. [ref](https://en.wikipedia.org/wiki/2023_Periodic_Review_of_Westminster_constituencies#New_and_abolished_constituencies).
* 2026-05-06: Senedd boundaries change. The 40 constituencies + 5 regions are abolished and replaced by 16 new constituencies. Existing `senc:` / `senr:` rows carry `validThrough=2026-05-05`; the new `senc:` rows carry `validFrom=2026-05-06`.
