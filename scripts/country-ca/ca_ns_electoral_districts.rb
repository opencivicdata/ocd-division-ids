#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Nova Scotia electoral district codes and names from electionsnovascotia.ca

class NS < Runner
  @csv_filename = "province-ns-electoral_districts.csv"
  @translatable = false # shapefile is unilingual

  def identifiers
    # Also available as a list.
    # http://electionsnovascotia.ca/geoginfo.asp
    ShapefileParser.new(
      "http://electionsnovascotia.ca/geography/downloads/NSElectoralDistrict_2012_fordistribution.zip",
      "province:ns/ped:", {
        :identifier => "DIST_NO",
        :name => "DISTRICT",
      }
    ).run
  end
end

NS.new.run(ARGV)
