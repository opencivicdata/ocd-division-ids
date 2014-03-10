#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes British Columbia electoral district codes and names from elections.bc.ca

class BC < Runner
  def names
    # Also available as table.
    # @see http://www3.elections.bc.ca/index.php/maps/electoral-maps-profiles/geographic-information-system-spatial-data-files-2012/
    ShapefileParser.new(
      "http://www3.elections.bc.ca/docs/map/redis12/GIS/Electoral%20District%20Boundaries.zip",
      "province:bc/ed:", {
        :id => "edAbbr",
        :name => "edName",
      }
    ).run
  end
end

BC.new("province-bc-electoral_districts.csv").run(ARGV)
