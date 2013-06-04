#!/bin/sh

# @see http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
DIR=$( cd "$( dirname "$0" )" && pwd )

$DIR/ca_ab_electoral_districts.rb identifiers > identifiers/country-ca/province-ab-electoral_districts.csv
$DIR/ca_bc_electoral_districts.rb identifiers > identifiers/country-ca/province-bc-electoral_districts.csv
$DIR/ca_federal_electoral_districts.rb identifiers > identifiers/country-ca/ca_federal_electoral_districts.csv
$DIR/ca_federal_electoral_districts.rb translations > mappings/country-ca-fr/ca_federal_electoral_districts.csv
$DIR/ca_mb_electoral_districts.rb identifiers > identifiers/country-ca/province-mb-electoral_districts.csv
$DIR/ca_mb_electoral_districts.rb translations > mappings/country-ca-fr/province-mb-electoral_districts.csv
$DIR/ca_nb_electoral_districts.rb identifiers > identifiers/country-ca/province-nb-electoral_districts.csv
$DIR/ca_nb_electoral_districts.rb translations > mappings/country-ca-fr/province-nb-electoral_districts.csv
$DIR/ca_ns_electoral_districts.rb identifiers > identifiers/country-ca/province-ns-electoral_districts.csv
$DIR/ca_nl_electoral_districts.rb identifiers > identifiers/country-ca/province-nl-electoral_districts.csv
$DIR/ca_on_electoral_districts.rb identifiers > identifiers/country-ca/province-on-electoral_districts.csv
$DIR/ca_on_electoral_districts.rb translations > mappings/country-ca-fr/province-on-electoral_districts.csv
$DIR/ca_pe_electoral_districts.rb identifiers > identifiers/country-ca/province-pe-electoral_districts.csv
$DIR/ca_qc_electoral_districts.rb identifiers > identifiers/country-ca/province-qc-electoral_districts.csv
$DIR/ca_sk_electoral_districts.rb identifiers > identifiers/country-ca/province-sk-electoral_districts.csv
