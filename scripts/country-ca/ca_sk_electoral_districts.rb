#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Saskatchewan electoral district codes and names from elections.sk.ca

require "nokogiri"

class SK < Runner
  @csv_filename = "province-sk-electoral_districts.csv"
  @translatable = false # shapefile is unilingual

  def identifiers
    # The zip file from geosask.ca contains one shapefile for each of the 58
    # electoral districts. Only the shapefile assigns numeric identifiers;
    # those names and identifiers do not co-occur anywhere else.
    Nokogiri::HTML(open("http://www.elections.sk.ca/publications/poll-maps/individual-constituencies")).css("table table a").each do |a|
      name = a.text.gsub(/\p{Space}+/, " ").strip
      next if name.empty? # last cells in table

      output("province:sk/ped:",
        name, # see comment above
        name)
    end
  end
end

SK.new.run(ARGV)
