#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes census subdivision codes and names from statcan.gc.ca

class CensusSubdivisions < Runner
  def names(language = "Eng")
    exceptions = {
      "4819006" => "County of Grande Prairie No. 1",
      "3519036" => "City of Markham",  # became a city since 2011
      "3528018" => "Corporation of Haldimand County",
      # SM: Specialized municipality
      "4811052" => "Strathcona County",
      "4815007" => "Municipality of Crowsnest Pass",
      "4815033" => "Municipality of Jasper",
      "4816037" => "Regional Municipality of Wood Buffalo",
      "4817095" => "Mackenzie County",
    }

    type_names = census_subdivision_type_names

    # @see https://www12.statcan.gc.ca/census-recensement/2011/dp-pd/hlt-fst/pd-pl/index-eng.cfm
    file = open("https://www12.statcan.gc.ca/census-recensement/2011/dp-pd/hlt-fst/pd-pl/FullFile.cfm?T=301&LANG=Eng&OFT=CSV&OFN=98-310-XWE2011002-301.CSV")
    # The CSV has an extra header row.
    file.gets
    # The CSV is in ISO-8859-1.
    text = file.read.force_encoding("ISO-8859-1").encode("UTF-8")

    puts CSV.generate_line(%w(id name name_fr classification organization_name number))
    CSV.parse(text, :headers => true, :skip_blanks => true).each do |row|
      code = row.fetch("Geographic code")
      name = row.fetch("Geographic name")
      type = row.fetch("Geographic type")
      organization_name = nil
      number = nil

      # Skip "Canada" row.
      next if code == "01"
      # Stop before footer.
      break if code == "Note:"

      if name == "Resort Mun. Stan.B.-Hope R.-Bayv.-Cavend.-N.Rust. (P.E.I.)"
        value = "Resort Municipality of Stanley Bridge-Hope River-Bayview-Cavendish-North Rustico"
      else
        value = name.
          squeeze(" ").                # Remove extra spaces, e.g. "Lot  1"
          sub(/ \([^)]+\)\z/, "").     # Remove region, e.g. "Toronto (Ont.)"
          sub(/ \(Part\)/, "").        # Remove "(Part)" e.g. "Flin Flon (Part)"
          sub(/(?<=No\.)(?=\S)/, " "). # Add a space after "No.", e.g. "Lesser Slave River No.124"
          sub(/, Labrador\z/, "").     # Remove subregion, e.g. "Cartwright, Labrador"
          sub(/ \(Labrador\)\z/, "")   # Remove subregion, e.g. "Charlottetown (Labrador)"

        # Expand "St." and "Ste." in New Brunswick and Quebec.
        if code[/\A(?:13|24)/]
          value.sub!(/\bSt(e)?\./, 'Saint\1')
        end
      end

      # @see https://www.statcan.gc.ca/subjects-sujets/standard-norme/sgc-cgt/2001/2001-supp4-eng.htm
      parts = value.split(" / ", 2)

      if exceptions.key?(code)
        organization_name = exceptions[code]
      else
        case type
        when "RGM"
          organization_name = "#{parts[0]} Regional Municipality"
        when "MD"
          organization_name = "Municipality of #{parts[0]}" # instead of Municipal district
        when "C", "CV", "CY", "MU", "T", "TP", "V", "VL"
          organization_name = "#{type_names[type]} #{code[0, 2] == "24" ? "de" : "of"} #{parts[0]}"
        end
      end

      if type == "RM" && code[0, 2] == "47"
        number = parts[0].match(/No\. (\d+)\z/)[1]
      end

      output("csd:", code, parts[0], parts[1] || parts[0], type, organization_name, number)
    end
  end
end

CensusSubdivisions.new("ca_census_subdivisions.csv").run(ARGV)
