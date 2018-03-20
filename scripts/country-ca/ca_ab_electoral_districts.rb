#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Alberta electoral district codes and names from altalis.com

class AB < Runner
  def initialize(*args)
    super

    add_command({
      :name        => "names-2017",
      :description => "Prints a CSV of identifiers and English names",
      :output_path => "identifiers/country-ca/province-ab-electoral_districts-2017.csv",
    })
  end

  def names
    # Also available as deeply-nested lists.
    # @see http://www.electionsalberta.ab.ca/Public%20Website/112.htm
    # Altalis now requires downloading the boundaries as a bundle via a form.
    ShapefileParser.new(
      "http://represent.opennorth.ca.s3.amazonaws.com/data/ab_ed.zip",
      "province:ab/ed:", {
        :id => "EDNUMBER",
        :name => "EDNAME",
      }
    ).run
  end

  def names_2017
    ShapefileParser.new(
      "http://www.elections.ab.ca/wp-content/uploads/2019Boundaries_ED-Shapefiles.zip",
      "province:ab/ed:", {
        :id => lambda{|record| "#{record.attributes["EDNumber20"]}-2017"},
        :name => "EDName2017",
        :validFrom => lambda{|record| "2019-05-31"},
      }
    ).run
  end
end

AB.new("province-ab-electoral_districts.csv").run(ARGV)
