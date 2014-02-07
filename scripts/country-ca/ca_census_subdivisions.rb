#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes census subdivision codes and names from statcan.gc.ca

class CensusSubdivisions < Runner
  @csv_filename = "ca_census_subdivisions.csv"
  @translatable = true

  def initialize
    super

    add_command({
      :name        => "types",
      :description => "Prints a CSV of identifiers and canonical census subdivision types",
      :directory   => "mappings/country-ca-types",
    })
  end

  def names(language = "Eng")
    each(language) do |row|
      if row["Geographic name"] == "Resort Mun. Stan.B.-Hope R.-Bayv.-Cavend.-N.Rust. (P.E.I.)"
        name = "Resort Municipality of Stanley Bridge-Hope River-Bayview-Cavendish-North Rustico"
      else
        name = row["Geographic name"].
          squeeze(" ").                # Remove extra spaces, e.g. "Lot  1"
          sub(/ \([^)]+\)\z/, "").     # Remove region, e.g. "Toronto (Ont.)"
          sub(/ \(Part\)/, "").        # Remove "(Part)" e.g. "Flin Flon (Part)"
          sub(/(?<=No\.)(?=\S)/, " "). # Add a space after "No.", e.g. "Lesser Slave River No.124"
          sub(/, Labrador\z/, "").     # Remove subregion, e.g. "Cartwright, Labrador"
          sub(/ \(Labrador\)\z/, "")   # Remove subregion, e.g. "Charlottetown (Labrador)"

        # Expand "St." and "Ste." in New Brunswick and Quebec.
        if row["Geographic code"][/\A(?:13|24)/]
          name.sub!(/\bSt(e)?\./, 'Saint\1')
        end

        # @see http://www.statcan.gc.ca/subjects-sujets/standard-norme/sgc-cgt/2001/2001-supp4-eng.htm
        if name[" / "]
          name = name.split(" / ", 2)[language == "Eng" ? 0 : 1]
        end
      end

      output("csd:",
        row["Geographic code"],
        name)
    end
  end

  def names_fr
    names("Fra")
  end

  def types
    each do |row|
      output("csd:",
        row["Geographic code"],
        row["Geographic type"])
    end
  end

private

  def each(language = "Eng")
    # @see http://www12.statcan.gc.ca/census-recensement/2011/dp-pd/hlt-fst/pd-pl/index-eng.cfm
    file = open("http://www12.statcan.gc.ca/census-recensement/2011/dp-pd/hlt-fst/pd-pl/FullFile.cfm?T=301&LANG=#{language}&OFT=CSV&OFN=98-310-XWE2011002-301.CSV")
    # The CSV has an extra header row.
    file.gets
    # The CSV is in ISO-8859-1.
    text = file.read.force_encoding("ISO-8859-1").encode("UTF-8")

    CSV.parse(text, :headers => true, :skip_blanks => true).each do |row|
      # Skip "Canada" row.
      next if row["Geographic code"] == "01"
      # Stop before footer.
      break if row["Geographic code"] == "Note:"

      yield(row)
    end
  end
end

CensusSubdivisions.new.run(ARGV)
