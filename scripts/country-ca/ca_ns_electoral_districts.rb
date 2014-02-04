#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Nova Scotia electoral district codes and names from electionsnovascotia.ca

class NS < Runner
  @csv_filename = "province-ns-electoral_districts.csv"
  @translatable = false # shapefile is unilingual

  def names
    ShapefileParser.new(
      "http://electionsnovascotia.ca/sites/default/files/NS_EDBoundaries2012.zip",
      "province:ns/ed:", {
        :identifier => "DIST_NO",
        :name => "DISTRICT",
      }
    ).run
  end
end

NS.new.run(ARGV)
