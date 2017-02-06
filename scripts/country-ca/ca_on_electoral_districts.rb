#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Ontario electoral district codes and names from elections.on.ca

class ON < Runner
  def initialize(*args)
    super

    add_command({
      :name        => "names-2015",
      :description => "Prints a CSV of identifiers and English names",
      :output_path => "identifiers/country-ca/province-on-electoral_districts-2015.csv",
    })
  end

  def names
    ShapefileParser.new(
      "http://www.elections.on.ca/content/dam/NGW/sitecontent/2016/preo/shapefiles/Electoral%20District%20Shapefile.zip",
      "province:on/ed:", {
        :id => "ED_ID",
        :name => lambda{|record| UnicodeUtils.downcase(record.attributes["ENGLISH_NA"].sub('CHATHAM--KENT--', 'CHATHAM-KENT--').gsub('--', '—')).gsub(/\b(?!(?:and|s|the)\b)(\w)/){UnicodeUtils.upcase($1)}},
      }
    ).run
  end

  def names_2015
    ShapefileParser.new(
      "http://www.elections.on.ca/content/dam/NGW/sitecontent/2017/preo/2018%20Electoral%20District%20Shapefile.zip",
      "province:on/ed:", {
        :id => lambda{|record| "#{record.attributes["ED_ID"]}-2015"},
        :name => "ENGLISH_NA",
        :validFrom => lambda{|record| "2018-06-07"},
      }
    ).run
  end
end

ON.new("province-on-electoral_districts.csv").run(ARGV)
