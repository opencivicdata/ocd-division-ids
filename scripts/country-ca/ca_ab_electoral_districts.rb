#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Alberta electoral district codes and names from altalis.com

class AB < Runner
  @csv_filename = "province-ab-electoral_districts.csv"
  @translatable = false # shapefile is unilingual

  def names
    # Also available as deeply-nested lists.
    # @see http://www.electionsalberta.ab.ca/Public%20Website/112.htm
    ShapefileParser.new(
      "http://altalis.com/Samples/Provincial%20Electoral%20Divisions%20Current%202010.zip",
      "province:ab/ed:", {
        :identifier => "EDNUMBER",
        :content => "EDNAME",
      }
    ).run
  end
end

AB.new.run(ARGV)
