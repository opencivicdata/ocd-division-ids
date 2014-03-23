#!/bin/sh

# @see http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
DIR=$( cd "$( dirname "$0" )" && pwd )

mkdir -p $DIR/../../identifiers/country-ca

$DIR/ca_census_divisions.rb            names > $DIR/../../identifiers/country-ca/ca_census_divisions.csv
$DIR/ca_census_subdivisions.rb         names > $DIR/../../identifiers/country-ca/ca_census_subdivisions.csv
$DIR/ca_census_place_names.rb          names > $DIR/../../identifiers/country-ca/ca_census_place_names.csv
$DIR/ca_federal_electoral_districts.rb names > $DIR/../../identifiers/country-ca/ca_federal_electoral_districts.csv
$DIR/ca_municipal_subdivisions.rb      names > $DIR/../../identifiers/country-ca/ca_municipal_subdivisions.csv
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
$DIR/ca_qc_montreal_boroughs.rb        names > $DIR/../../identifiers/country-ca/census_subdivision-montreal-boroughs.csv
$DIR/ca_qc_quebec_boroughs.rb          names > $DIR/../../identifiers/country-ca/census_subdivision-quebec-boroughs.csv
$DIR/ca_qc_quebec_districts.rb         names > $DIR/../../identifiers/country-ca/census_subdivision-quebec-districts.csv

$DIR/ca_federal_electoral_districts.rb names-fr > $DIR/../../identifiers/country-ca/ca_federal_electoral_districts-name_fr.csv
$DIR/ca_provinces_and_territories.rb   names-fr > $DIR/../../identifiers/country-ca/ca_provinces_and_territories-name_fr.csv
$DIR/ca_regions.rb                     names-fr > $DIR/../../identifiers/country-ca/ca_regions-name_fr.csv

$DIR/ca_municipal_subdivisions.rb      posts-count > $DIR/../../identifiers/country-ca/ca_municipal_subdivisions-posts_count.csv
$DIR/ca_municipal_subdivisions.rb      has-children > $DIR/../../identifiers/country-ca/ca_municipal_subdivisions-has_children.csv
$DIR/ca_municipal_subdivisions.rb      parent-id > $DIR/../../identifiers/country-ca/ca_municipal_subdivisions-parent_id.csv
$DIR/ca_municipal_subdivisions.rb      data-catalog > $DIR/../../identifiers/country-ca/ca_municipal_subdivisions-data_catalog.csv

$DIR/ca_qc_montreal_boroughs.rb urls   > $DIR/../../identifiers/country-ca/census_subdivision-montreal-boroughs-url.csv
$DIR/ca_census_subdivision_urls.rb     > $DIR/../../identifiers/country-ca/ca_census_subdivisions-url.csv # slow
