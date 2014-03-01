#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Quebec district codes and names from ville.quebec.qc.ca

class Quebec < Runner
  @csv_filename = "census_subdivision-quebec-districts.csv"
  @translatable = false # data source is unilingual

  def initialize
    super

    add_command({
      :name        => "numeric",
      :description => "Prints a CSV of identifiers and numeric identifiers",
      :directory   => "mappings/country-ca-numeric",
    })
  end

  def names
    ShapefileParser.new(
      "http://donnees.ville.quebec.qc.ca/Handler.ashx?id=43&f=SHP",
      "csd:2423027/district:", {
        :content => "NOM",
        :sort_key => "CODE",
      },
      lambda do |record|
        record.attributes.fetch("DATE_FIN") == Date.new(2017, 11, 5)
      end,
    ).run
  end

  def numeric
    ShapefileParser.new(
      "http://donnees.ville.quebec.qc.ca/Handler.ashx?id=43&f=SHP",
      "csd:2423027/district:", {
        :identifier => "NOM",
        :content => "CODE",
        :sort_key => "CODE",
      },
      lambda do |record|
        record.attributes.fetch("DATE_FIN") == Date.new(2017, 11, 5)
      end,
    ).run
  end
end

Quebec.new.run(ARGV)
