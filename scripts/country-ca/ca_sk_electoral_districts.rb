#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Saskatchewan electoral district codes and names from elections.sk.ca

class SK < Runner
  def names
    # Only the shapefile assigns numeric identifiers; those names and
    # identifiers do not co-occur anywhere else.
    ShapefileParser.new(
      "http://electionssk1.blob.core.windows.net/shapefiles/Constit_2012.zip",
      "province:sk/ed:", {
        :id => "Con_Num",
        :name => "Con_Name",
      }
    ).run
    # Nokogiri::HTML(open("http://www.elections.sk.ca/publications/poll-maps/individual-constituencies")).css("table table a").each do |a|
    #   name = a.text.normalize_space.strip
    #   next if name.empty? # last cells in table

    #   output("province:sk/ed:", name, name)
    # end
  end
end

SK.new("province-sk-electoral_districts.csv").run(ARGV)
