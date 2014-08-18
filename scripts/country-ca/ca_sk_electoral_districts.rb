#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Saskatchewan electoral district codes and names from elections.sk.ca

class SK < Runner
  def names
    # The zip file from geosask.ca contains one shapefile for each of the 58
    # electoral districts. Only the shapefile assigns numeric identifiers;
    # those names and identifiers do not co-occur anywhere else.
    ShapefileParser.new(
      "http://represent.opennorth.ca.s3.amazonaws.com/data/sk_ed.zip",
      "province:sk/ed:", {
        :id => "CON_NUM",
        :name => lambda{|record| record.attributes["CON_NAME"].downcase.gsub(/\b([a-z])/){|letter| letter.upcase}},
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
