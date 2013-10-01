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

    # The CSV from the contains accents, but not URLs, and misspells "Lasalle".
    # @see http://donnees.ville.montreal.qc.ca/fiche/arros-liste/
    # Tempfile.open('csv', :encoding => 'binary') do |f|
    #   f.binmode
    #   f.write(open('http://depot.ville.montreal.qc.ca/arros-liste/data.zip').string)
    #   f.rewind
    #   Zip::ZipFile.open(f) do |zipfile|
    #     entry = zipfile.entries.find{|entry| File.extname(entry.name) == ".csv"}
    #     if entry
    #       CSV.parse(zipfile.read(entry), :headers => true).map do |record|
    #         name = record['Nom officiel'].force_encoding('windows-1252').encode('UTF-8')
    #         {
    #           :identifier => name.gsub(/[—–]/, "-"), # m- or n-dash to hyphen
    #           :name => name.gsub("–", "—"), # n-dash to m-dash
    #         }
    #       end
    #     else
    #       raise "CSV file not found!"
    #     end
    #   end
    # end

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
