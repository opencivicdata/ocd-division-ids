#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Ontario electoral district codes and names from elections.on.ca

class ON < Runner
  def names
    ShapefileParser.new(
      "http://www.elections.on.ca/content/dam/NGW/sitecontent/2016/preo/shapefiles/Electoral%20District%20Shapefile.zip",
      "province:on/ed:", {
        :id => "ED_ID",
        :name => lambda{|record| UnicodeUtils.downcase(record.attributes["ENGLISH_NA"].sub('CHATHAM--KENT--', 'CHATHAM-KENT--').gsub('--', '—')).gsub(/\b(?!(?:and|s|the)\b)(\w)/){UnicodeUtils.upcase($1)}},
      }
    ).run
  end
end

ON.new("province-on-electoral_districts.csv").run(ARGV)
