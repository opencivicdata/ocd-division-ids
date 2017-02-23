#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes census division codes and names from Statistics Canada

class CensusDivisions < Runner
  def names
    # @see http://www12.statcan.gc.ca/census-recensement/2016/dp-pd/hlt-fst/pd-pl/index-eng.cfm
    text = open("http://www12.statcan.gc.ca/census-recensement/2016/dp-pd/hlt-fst/pd-pl/Tables/CompFile.cfm?Lang=Eng&T=701&OFT=FULLCSV").read
    text = text.force_encoding("iso-8859-1").encode("utf-8")

    type_names = census_division_type_names.invert

    puts CSV.generate_line(%w(id name name_fr classification))
    CSV.parse(text, :headers => true).each do |row|
      # Stop before footer.
      break if row.empty?

      # Remove extra spaces, e.g. "Lot  1"
      output("cd:",
        row.fetch("Geographic code"),
        row.fetch("Geographic name, english").squeeze(" "),
        row.fetch("Geographic name, french").squeeze(" "),
        type_names.fetch(row.fetch("Geographic type, english")))
    end
  end
end

CensusDivisions.new("ca_census_divisions.csv").run(ARGV)
