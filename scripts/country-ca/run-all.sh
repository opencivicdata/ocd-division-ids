#!/bin/sh

# @see https://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
DIR=$( cd "$( dirname "$0" )" && pwd )

mkdir -p $DIR/../../identifiers/country-ca

echo 'ca_census_divisions'
$DIR/ca_census_divisions.rb            names > $DIR/../../identifiers/country-ca/ca_census_divisions.csv
echo 'ca_census_subdivisions'
$DIR/ca_census_subdivisions.rb         names > $DIR/../../identifiers/country-ca/ca_census_subdivisions.csv
echo 'ca_federal_electoral_districts'
$DIR/ca_federal_electoral_districts.rb names > $DIR/../../identifiers/country-ca/ca_federal_electoral_districts.csv
echo 'ca_municipal_subdivisions'
$DIR/ca_municipal_subdivisions.rb      names > $DIR/../../identifiers/country-ca/ca_municipal_subdivisions.csv
echo 'ca_provinces_and_territories'
$DIR/ca_provinces_and_territories.rb   names > $DIR/../../identifiers/country-ca/ca_provinces_and_territories.csv
echo 'ca_regions'
$DIR/ca_regions.rb                     names > $DIR/../../identifiers/country-ca/ca_regions.csv
echo 'ca_ab_electoral_districts'
$DIR/ca_ab_electoral_districts.rb      names > $DIR/../../identifiers/country-ca/province-ab-electoral_districts.csv
echo 'ca_bc_electoral_districts'
$DIR/ca_bc_electoral_districts.rb      names > $DIR/../../identifiers/country-ca/province-bc-electoral_districts.csv
echo 'ca_mb_electoral_districts'
$DIR/ca_mb_electoral_districts.rb      names > $DIR/../../identifiers/country-ca/province-mb-electoral_districts.csv
echo 'ca_nb_electoral_districts'
$DIR/ca_nb_electoral_districts.rb      names > $DIR/../../identifiers/country-ca/province-nb-electoral_districts.csv
echo 'ca_ns_electoral_districts'
$DIR/ca_ns_electoral_districts.rb      names > $DIR/../../identifiers/country-ca/province-ns-electoral_districts.csv
echo 'ca_nl_electoral_districts'
$DIR/ca_nl_electoral_districts.rb      names > $DIR/../../identifiers/country-ca/province-nl-electoral_districts.csv
echo 'ca_on_electoral_districts'
$DIR/ca_on_electoral_districts.rb      names > $DIR/../../identifiers/country-ca/province-on-electoral_districts.csv
echo 'ca_pe_electoral_districts'
$DIR/ca_pe_electoral_districts.rb      names > $DIR/../../identifiers/country-ca/province-pe-electoral_districts.csv
echo 'ca_qc_electoral_districts'
$DIR/ca_qc_electoral_districts.rb      names > $DIR/../../identifiers/country-ca/province-qc-electoral_districts.csv
echo 'ca_sk_electoral_districts'
$DIR/ca_sk_electoral_districts.rb      names > $DIR/../../identifiers/country-ca/province-sk-electoral_districts.csv
echo 'ca_qc_montreal_boroughs'
$DIR/ca_qc_montreal_boroughs.rb        names > $DIR/../../identifiers/country-ca/census_subdivision-montreal-boroughs.csv

echo 'ca_federal_electoral_districts'
$DIR/ca_federal_electoral_districts.rb names-fr > $DIR/../../identifiers/country-ca/ca_federal_electoral_districts-name_fr.csv
echo 'ca_provinces_and_territories'
$DIR/ca_provinces_and_territories.rb   names-fr > $DIR/../../identifiers/country-ca/ca_provinces_and_territories-name_fr.csv
echo 'ca_regions'
$DIR/ca_regions.rb                     names-fr > $DIR/../../identifiers/country-ca/ca_regions-name_fr.csv

echo 'ca_federal_electoral_districts names-2013'
$DIR/ca_federal_electoral_districts.rb names-2013 > $DIR/../../identifiers/country-ca/ca_federal_electoral_districts-2013.csv
echo 'ca_bc_electoral_districts names-2015'
$DIR/ca_bc_electoral_districts.rb names-2015 > $DIR/../../identifiers/country-ca/province-bc-electoral_districts-2015.csv
echo 'ca_on_electoral_districts names-2015'
$DIR/ca_on_electoral_districts.rb names-2015 > $DIR/../../identifiers/country-ca/province-on-electoral_districts-2015.csv
echo 'ca_municipal_subdivisions posts-count'
$DIR/ca_municipal_subdivisions.rb      posts-count > $DIR/../../identifiers/country-ca/ca_municipal_subdivisions-posts_count.csv
echo 'ca_municipal_subdivisions has-children'
$DIR/ca_municipal_subdivisions.rb      has-children > $DIR/../../identifiers/country-ca/ca_municipal_subdivisions-has_children.csv
echo 'ca_municipal_subdivisions parent-id'
$DIR/ca_municipal_subdivisions.rb      parent-id > $DIR/../../identifiers/country-ca/ca_municipal_subdivisions-parent_id.csv

echo 'ca_qc_montreal_boroughs'
$DIR/ca_qc_montreal_boroughs.rb urls   > $DIR/../../identifiers/country-ca/census_subdivision-montreal-boroughs-url.csv
