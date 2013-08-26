#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Montreal arrondissements codes and names from ville.montreal.qc.ca

require "nokogiri"

class Montreal < Runner
  @csv_filename = "census_subdivision-montreal-arrondissements.csv"
  @translatable = false # shapefile is unilingual

  def initialize
    super

    add_command({
      :name        => "urls",
      :description => "Prints a CSV of identifiers and URLs",
      :directory   => "mappings/country-ca-urls",
    })
  end

  def names
    rows.each do |row|
      output("csd:2466023/arrondissement:",
        row[:identifier],
        row[:name])
    end
  end

  def urls
    rows.each do |row|
      output("csd:2466023/arrondissement:",
        row[:identifier],
        row[:url])
    end
  end

private

  def rows
    # The shapefile from Montreal's open data portal contains no accents.
    # @see http://donnees.ville.montreal.qc.ca/fiche/polygones-arrondissements/
    Nokogiri::HTML(open("http://ville.montreal.qc.ca/portal/page?_pageid=5798,85813661&_dad=portal&_schema=PORTAL")).css("#nav_coll a").map do |a|
      {
        :identifier => a.text.gsub(/[—–]/, "-"), # m- or n-dash to hyphen
        :name => a.text.gsub("–", "—").gsub('’', "'"), # n-dash to m-dash
        :url => "http://ville.montreal.qc.ca#{a[:href]}",
      }
    end
  end
end

Montreal.new.run(ARGV)
