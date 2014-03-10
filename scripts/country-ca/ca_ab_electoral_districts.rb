#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Alberta electoral district codes and names from altalis.com

class AB < Runner
  def names
    # Also available as deeply-nested lists.
    # @see http://www.electionsalberta.ab.ca/Public%20Website/112.htm
    ShapefileParser.new(
      "http://altalis.com/Samples/Provincial%20Electoral%20Divisions%20Current%202010.zip",
      "province:ab/ed:", {
        :id => "EDNUMBER",
        :name => "EDNAME",
      }
    ).run
  end
end

AB.new("province-ab-electoral_districts.csv").run(ARGV)
