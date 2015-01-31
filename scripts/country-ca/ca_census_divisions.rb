#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes census division codes and names from statcan.gc.ca

class CensusDivisions < Runner
  def names
    type_names = census_division_type_names

    # @see https://www12.statcan.gc.ca/census-recensement/2011/dp-pd/hlt-fst/pd-pl/index-eng.cfm
    file = open("https://www12.statcan.gc.ca/census-recensement/2011/dp-pd/hlt-fst/pd-pl/FullFile.cfm?T=701&LANG=Eng&OFT=CSV&OFN=98-310-XWE2011002-701.CSV")
    # The CSV has an extra header row.
    file.gets
    # The CSV is in ISO-8859-1.
    text = file.read.force_encoding("ISO-8859-1").encode("UTF-8")

    puts CSV.generate_line(%w(id name name_fr classification))
    CSV.parse(text, :headers => true, :skip_blanks => true).each do |row|
      code = row.fetch("Geographic code")
      name = row.fetch("Geographic name")
      type = row.fetch("Geographic type")

      # Skip "Canada" row.
      next if code == "01"
      # Stop before footer.
      break if code == "Note:"

      value = name.
        squeeze(" ").           # Remove extra spaces, e.g. "Lot  1"
        sub(/ \([^)]+\)\z/, "") # Remove region, e.g. "Toronto (Ont.)"

      # @see http://www.statcan.gc.ca/subjects-sujets/standard-norme/sgc-cgt/2001/2001-supp4-eng.htm
      parts = value.split(" / ", 2)

      output("cd:", code, parts[0], parts[1] || parts[0], type)
    end
  end
end

CensusDivisions.new("ca_census_divisions.csv").run(ARGV)
