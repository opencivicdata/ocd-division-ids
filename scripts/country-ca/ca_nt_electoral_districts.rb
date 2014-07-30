#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Northwest Territories electoral district codes and names

class NT < Runner
  def names
    ShapefileParser.new(
      "http://represent.opennorth.ca.s3.amazonaws.com/data/nt_ed.zip",
      "territory:nt/ed:", {
        :id => "EDNWTF_ID",
        :name => "ED",
      }
    ).run
  end
end

NT.new("territory-nt-electoral_districts.csv").run(ARGV)
