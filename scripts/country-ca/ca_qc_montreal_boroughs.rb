#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Montreal boroughs codes and names from ville.montreal.qc.ca

class Montreal < Runner
  def initialize(*args)
    super

    add_command({
      :name        => "urls",
      :description => "Prints a CSV of identifiers and URLs",
      :output_path => "identifiers/country-ca/census_subdivision-montreal-boroughs-url.csv",
    })
  end

  def names
    puts CSV.generate_line(%w(id name abbreviation))
    csv.map do |row|
      name = row['Nom-officiel'].gsub("–", "—").gsub('’', "'") # n-dash to m-dash
      output("csd:2466023/borough:", row['No-arro-election'], name, row['Code3L'])
    end
  end

  def urls
    map = {}
    csv.each do |row|
      name = row['Nom-officiel'].gsub("–", "—").gsub('’', "'") # n-dash to m-dash
      map[name] = row['No-arro-election']
    end

    puts CSV.generate_line(%w(id url))
    Nokogiri::HTML(open("http://ville.montreal.qc.ca/portal/page?_pageid=5798,85813661&_dad=portal&_schema=PORTAL")).css("#nav_coll a").map do |a|
      name = a.text.gsub("–", "—").gsub('’', "'") # n-dash to m-dash
      output("csd:2466023/borough:", map.fetch(name), "http://ville.montreal.qc.ca#{a[:href]}")
    end
  end

private

  def csv
    # The shapefile from Montreal's open data portal contains no accents.
    # @see http://donnees.ville.montreal.qc.ca/fiche/polygones-arrondissements/

    # @see http://donnees.ville.montreal.qc.ca/dataset/arros-liste
    file = open("http://donnees.ville.montreal.qc.ca/storage/f/2013-10-13T00%3A03%3A13.959Z/liste-arrondissements.csv")
    text = file.read.force_encoding("UTF-8")
    CSV.parse(text, :headers => true)
  end
end

Montreal.new("census_subdivision-montreal-boroughs.csv").run(ARGV)
