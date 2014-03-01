#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Quebec borough codes and names from ville.quebec.qc.ca

require "nokogiri"

class Quebec < Runner
  @csv_filename = "census_subdivision-quebec-boroughs.csv"
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
      "http://donnees.ville.quebec.qc.ca/Handler.ashx?id=2&f=SHP",
      "csd:2423027/borough:", {
        :content => "NOM",
        :sort_key => "CODE",
      }
    ).run
  end

  def numeric
    ShapefileParser.new(
      "http://donnees.ville.quebec.qc.ca/Handler.ashx?id=2&f=SHP",
      "csd:2423027/borough:", {
        :identifier => "NOM",
        :content => "CODE",
        :sort_key => "CODE",
      }
    ).run
  end
end

Quebec.new.run(ARGV)
