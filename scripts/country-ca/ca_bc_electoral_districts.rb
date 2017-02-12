#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes British Columbia electoral district codes and names from elections.bc.ca

class BC < Runner
  def initialize(*args)
    super

    add_command({
      :name        => "names-2015",
      :description => "Prints a CSV of identifiers and English names",
      :output_path => "identifiers/country-ca/province-bc-electoral_districts-2015.csv",
    })
  end

  def names
    # Also available as table.
    # @see http://www.elections.bc.ca/index.php/maps/electoral-maps/geographic-information-system-spatial-data-files-2012/
    ShapefileParser.new(
      "https://catalogue.data.gov.bc.ca/dataset/c864f294-d302-4630-bde3-a0551735b309/resource/dc567bfb-488b-4765-b544-6bd02f61f736/download/edsre2008.zip",
      "province:bc/ed:", {
        :id => "ED_ABBREV",
        :name => "ED_NAME",
      }
    ).run
  end

  def names_2015
    ShapefileParser.new(
      "https://catalogue.data.gov.bc.ca/dataset/9530a41d-6484-41e5-b694-acb76e212a58/resource/34eedf53-c60b-4237-bf6e-81228a51ab12/download/edsre2015.zip",
      "province:bc/ed:", {
        :id => lambda{|record| "#{record.attributes["ED_ABBREV"]}-2015"},
        :name => "ED_NAME",
        :validFrom => lambda{|record| "2017-05-09"},
      }
    ).run
  end
end

BC.new("province-bc-electoral_districts.csv").run(ARGV)
