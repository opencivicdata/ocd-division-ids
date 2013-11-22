#!/bin/sh

# @see http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
DIR=$( cd "$( dirname "$0" )" && pwd )

mkdir -p $DIR/../../identifiers/country-ca $DIR/../../mappings/country-ca-{abbr,abbr-fr,fr,sgc,types}

$DIR/ca_census_divisions.rb            names > $DIR/../../identifiers/country-ca/ca_census_divisions.csv
$DIR/ca_census_subdivisions.rb         names > $DIR/../../identifiers/country-ca/ca_census_subdivisions.csv
$DIR/ca_federal_electoral_districts.rb names > $DIR/../../identifiers/country-ca/ca_federal_electoral_districts.csv
$DIR/ca_provinces_and_territories.rb   names > $DIR/../../identifiers/country-ca/ca_provinces_and_territories.csv
$DIR/ca_regions.rb                     names > $DIR/../../identifiers/country-ca/ca_regions.csv
$DIR/ca_ab_electoral_districts.rb      names > $DIR/../../identifiers/country-ca/province-ab-electoral_districts.csv
$DIR/ca_bc_electoral_districts.rb      names > $DIR/../../identifiers/country-ca/province-bc-electoral_districts.csv
$DIR/ca_mb_electoral_districts.rb      names > $DIR/../../identifiers/country-ca/province-mb-electoral_districts.csv
$DIR/ca_nb_electoral_districts.rb      names > $DIR/../../identifiers/country-ca/province-nb-electoral_districts.csv
$DIR/ca_ns_electoral_districts.rb      names > $DIR/../../identifiers/country-ca/province-ns-electoral_districts.csv
$DIR/ca_nl_electoral_districts.rb      names > $DIR/../../identifiers/country-ca/province-nl-electoral_districts.csv
$DIR/ca_on_electoral_districts.rb      names > $DIR/../../identifiers/country-ca/province-on-electoral_districts.csv
$DIR/ca_pe_electoral_districts.rb      names > $DIR/../../identifiers/country-ca/province-pe-electoral_districts.csv
$DIR/ca_qc_electoral_districts.rb      names > $DIR/../../identifiers/country-ca/province-qc-electoral_districts.csv
$DIR/ca_sk_electoral_districts.rb      names > $DIR/../../identifiers/country-ca/province-sk-electoral_districts.csv
$DIR/ca_qc_montreal_arrondissements.rb names > $DIR/../../identifiers/country-ca/census_subdivision-montreal-arrondissements.csv

$DIR/ca_census_divisions.rb            names-fr > $DIR/../../mappings/country-ca-fr/ca_census_divisions.csv
$DIR/ca_census_subdivisions.rb         names-fr > $DIR/../../mappings/country-ca-fr/ca_census_subdivisions.csv
$DIR/ca_federal_electoral_districts.rb names-fr > $DIR/../../mappings/country-ca-fr/ca_federal_electoral_districts.csv
$DIR/ca_provinces_and_territories.rb   names-fr > $DIR/../../mappings/country-ca-fr/ca_provinces_and_territories.csv
$DIR/ca_regions.rb                     names-fr > $DIR/../../mappings/country-ca-fr/ca_regions.csv
$DIR/ca_mb_electoral_districts.rb      names-fr > $DIR/../../mappings/country-ca-fr/province-mb-electoral_districts.csv
$DIR/ca_nb_electoral_districts.rb      names-fr > $DIR/../../mappings/country-ca-fr/province-nb-electoral_districts.csv
$DIR/ca_on_electoral_districts.rb      names-fr > $DIR/../../mappings/country-ca-fr/province-on-electoral_districts.csv

$DIR/ca_census_divisions.rb            types > $DIR/../../mappings/country-ca-types/ca_census_divisions.csv
$DIR/ca_census_subdivisions.rb         types > $DIR/../../mappings/country-ca-types/ca_census_subdivisions.csv

$DIR/ca_qc_montreal_arrondissements.rb urls > $DIR/../../mappings/country-ca-urls/census_subdivision-montreal-arrondissements.csv
$DIR/ca_census_subdivision_urls.rb     > $DIR/../../mappings/country-ca-urls/ca_census_subdivisions.csv

$DIR/ca_provinces_and_territories.rb   abbreviations > $DIR/../../mappings/country-ca-abbr/ca_provinces_and_territories.csv
$DIR/ca_provinces_and_territories.rb   abbreviations-fr > $DIR/../../mappings/country-ca-abbr-fr/ca_provinces_and_territories.csv
$DIR/ca_provinces_and_territories.rb   sgc-codes > $DIR/../../mappings/country-ca-sgc/ca_provinces_and_territories.csv
$DIR/ca_qc_montreal_arrondissements.rb numeric > $DIR/../../mappings/country-ca-numeric/ca_qc_montreal_arrondissements.csv
