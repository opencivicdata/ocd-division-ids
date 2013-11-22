#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Montreal arrondissements codes and names from ville.montreal.qc.ca

require "nokogiri"

class Montreal < Runner
  @csv_filename = "census_subdivision-montreal-arrondissements.csv"
  @translatable = false # data source is unilingual

  def initialize
    super

    add_command({
      :name        => "urls",
      :description => "Prints a CSV of identifiers and URLs",
      :directory   => "mappings/country-ca-urls",
    })

    add_command({
      :name        => "numeric",
      :description => "Prints a CSV of identifiers and numeric identifiers",
      :directory   => "mappings/country-ca-numeric",
    })
  end

  def names
    rows.each do |row|
      output("csd:2466023/arrondissement:",
        row[:identifier],
        row[:name])
    end
  end

  def numeric
    rows.each do |row|
      output("csd:2466023/arrondissement:",
        row[:identifier],
        row[:numeric])
    end
  end

  def urls
    Nokogiri::HTML(open("http://ville.montreal.qc.ca/portal/page?_pageid=5798,85813661&_dad=portal&_schema=PORTAL")).css("#nav_coll a").map do |a|
      output("csd:2466023/arrondissement:",
        a.text.gsub(/[—–]/, "-"), # m- or n-dash to hyphen
        "http://ville.montreal.qc.ca#{a[:href]}")
    end
  end

private

  def rows
    # The shapefile from Montreal's open data portal contains no accents.
    # @see http://donnees.ville.montreal.qc.ca/fiche/polygones-arrondissements/

    # This CSV contains accents, but not URLs, and misspells "Lasalle".
    # @see http://donnees.ville.montreal.qc.ca/dataset/arros-liste
    file = open('http://donnees.ville.montreal.qc.ca/storage/f/2013-10-13T00%3A03%3A13.959Z/liste-arrondissements.csv')
    # The CSV is in ISO-8859-1.
    text = file.read.force_encoding("UTF-8")

    CSV.parse(text, :headers => true).map do |row|
      {
        :identifier => row['Nom-officiel'].gsub(/[—–]/, "-"), # m- or n-dash to hyphen
        :name => row['Nom-officiel'].gsub("–", "—").gsub('’', "'"), # n-dash to m-dash
        :numeric => row['No-arro-election'], # Élections Montréal
      }
    end
  end
end

Montreal.new.run(ARGV)
