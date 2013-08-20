#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Montreal arrondissements codes and names from ville.montreal.qc.ca

require "nokogiri"

class Montreal < Runner
  @csv_filename = "census_subdivision-montreal-arrondissements.csv"
  @translatable = false # shapefile is unilingual

  def names
    # The shapefile from Montreal's open data portal contains no accents.
    # @see http://donnees.ville.montreal.qc.ca/fiche/polygones-arrondissements/
    Nokogiri::HTML(open("http://ville.montreal.qc.ca/portal/page?_pageid=5798,85813661&_dad=portal&_schema=PORTAL")).css("#nav_coll a").each do |a|
      name = a.text
      output("csd:2466023/arrondissement:",
        name.gsub(/[—–]/, "-"), # m- or n-dash to hyphen
        name.gsub("–", "—")) # n-dash to m-dash
    end
  end
end

Montreal.new.run(ARGV)
