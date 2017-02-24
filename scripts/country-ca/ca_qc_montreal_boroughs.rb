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
      output("csd:2466023/borough:", row.fetch('No-arro-élection'), clean_name(row.fetch('Nom officiel')), row.fetch('Code 3L'))
    end
  end

  def urls
    map = {}
    csv.each do |row|
      map[clean_name(row.fetch('Nom officiel'))] = row.fetch('No-arro-élection')
    end

    puts CSV.generate_line(%w(id url))
    Nokogiri::HTML(open("http://ville.montreal.qc.ca/portal/page?_pageid=5798,85813661&_dad=portal&_schema=PORTAL")).css("#nav_coll a").map do |a|
      output("csd:2466023/borough:", map.fetch(clean_name(a.text)), "http://ville.montreal.qc.ca#{a[:href]}")
    end
  end

private

  def clean_name(name)
    name.gsub("–", "—").gsub('’', "'").sub(/Le /, "") # n-dash to m-dash
  end

  def csv
    # The shapefile from Montreal's open data portal contains no accents.
    # @see http://donnees.ville.montreal.qc.ca/fiche/polygones-arrondissements/

    # @see http://donnees.ville.montreal.qc.ca/dataset/arros-liste
    file = open("http://donnees.ville.montreal.qc.ca/dataset/ddfdbcd9-de86-4b44-9b41-c293d7bfef14/resource/87af3a62-ee9a-40ad-b7d9-517ab3f12fad/download/liste-arrondissements.csv")
    text = file.read.force_encoding("utf-8")
    CSV.parse(text, :headers => true)
  end
end

Montreal.new("census_subdivision-montreal-boroughs.csv").run(ARGV)
