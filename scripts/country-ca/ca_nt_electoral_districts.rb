#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Northwest Territories electoral district codes and names

# https://newsinteractives.cbc.ca/elections/northwest-territories/2023/results/
# https://en.wikipedia.org/wiki/Category:Northwest_Territories_territorial_electoral_districts
REPLACEMENTS = {
  "Mackenzie-Delta" => "Mackenzie Delta",
  "Tu Nedhé - Wiilideh" => "Tu Nedhé-Wiilideh",
}

class NT < Runner
  def names
    ShapefileParser.new(
      "https://www.geomatics.gov.nt.ca/en/electoral-district-boundaries",
      "territory:nt/ed:", {
        :name => lambda { |record|
          name = record.attributes["ED"].force_encoding("utf-8").encode("utf-8")
          REPLACEMENTS.fetch(name, name)
        },
      }
    ).run
  end
end

NT.new("territory-nt-electoral_districts.csv").run(ARGV)
