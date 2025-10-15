This folder list the following administrative divisions of Colombia : 
* Departments of Colombia
  [ref](https://en.wikipedia.org/wiki/Departments_of_Colombia) as **department**.
*  Bogotá, Distrito Capitalref[https://en.wikipedia.org/wiki/Bogot%C3%A1] as
   **capital_district**.
*  Indigenous communities, Afro-Colombian communities and Colombian citizens resident abroad as **special**.


The OCD identifiers are created based on the HASC code (Used sources [CO department](http://www.statoids.com/uco.html))


SPECIAL DISTRICTS — COLOMBIA (CHAMBER OF REPRESENTATIVES)
=========================================================

This repository maintains mappings for OCD-IDs. In Colombia, the Chamber of Representatives includes several special districts ("circunscripciones especiales") in addition to the regular territorial contests. Below is how we model these districts and where they belong in the contest hierarchy.

WHAT COUNTS AS A "SPECIAL DISTRICT"
-----------------------------------
- Peace Districts: Seats created for regions affected by the armed conflict.
  Modeling rule: Each peace seat is its own special-scope contest within the Chamber of Representatives.
  Examples used in this project: Sur de Tolima, Urabá Antioquia.

- Raizal Community: Distinct community-based district for the Archipelago of San Andrés, Providencia and Santa Catalina.
  Modeling rule: Separate special-scope contest (not merged with Indigenous).

- Indigenous Communities: Community-based district.
  Modeling rule: Its own special-scope contest, separate from Raizal.

- Foreign ("Colombian citizens resident abroad"): International district for Colombians residing outside the country.
  Modeling rule: Special-scope contest under the Chamber of Representatives.

HOW WE REPRESENT SPECIFIC CASES
-------------------------------
- Sur de Tolima
  Contest (Body): Chamber of Representatives
  Scope: Special
  Notes: One of the 16 Peace districts; modeled as its own contest.

- Urabá Antioquia
  Contest (Body): Chamber of Representatives
  Scope: Special
  Notes: One of the 16 Peace districts; modeled as its own contest.

- Raizal Community
  Contest (Body): Chamber of Representatives
  Scope: Special
  Notes: Separate from Indigenous; each has its own contest.

- Foreign ("Colombian citizens resident abroad")
  Contest (Body): Chamber of Representatives
  Scope: Special
  Notes: International district under the Chamber; modeled as its own contest.

SOURCE
------
All definitions above are based on Colombia’s official guidance:

PDF: [docs/INSCRIPCION-DE-CANDIDATOS-2026-1.pdf](https://moe.org.co/wp-content/uploads/2025/03/INSCRIPCION-DE-CANDIDATOS-2026-1.pdf)

Reference site:
https://centralpdet.renovacionterritorio.gov.co/micrositio-uraba-antioqueno/
