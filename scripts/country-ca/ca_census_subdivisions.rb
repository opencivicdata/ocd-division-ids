#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes census subdivision codes and names from Statistics Canada

class CensusSubdivisions < Runner
  def names
    # @see http://www12.statcan.gc.ca/census-recensement/2016/dp-pd/hlt-fst/pd-pl/index-eng.cfm
    text = open("http://www12.statcan.gc.ca/census-recensement/2016/dp-pd/hlt-fst/pd-pl/Tables/CompFile.cfm?Lang=Eng&T=301&OFT=FULLCSV").read
    text = text.force_encoding("iso-8859-1").encode("utf-8")

    type_names = census_subdivision_type_names
    type_names_inverse = type_names.invert

    puts CSV.generate_line(%w(id name name_fr classification organization_name number))
    CSV.parse(text, :headers => true).each do |row|
      # Stop before footer.
      break if row.empty?

      type_name_en = row.fetch("CSD type, english")
      type_name_fr = row.fetch("CSD type, french")
      if type_name_en == type_name_fr
        type_name = type_name_en
      else
        type_name = "#{type_name_en} / #{type_name_fr}"
      end

      code = row.fetch("Geographic code")
      name_en = name(row.fetch("Geographic name, english"), code)
      name_fr = name(row.fetch("Geographic name, french"), code)
      type = type_names_inverse.fetch(type_name.downcase)
      organization_name = nil
      number = nil

      case type
      when "RGM" # Regional municipality
        organization_name = "#{name_en} Regional Municipality"
      when "MD" # Municipal district
        organization_name = "Municipality of #{name_en}"
      when "C", "CV", "CY", "M", "MU", "T", "TP", "TV", "V", "VL"
        if code[0, 2] == "24"
          organization_name = "#{type_name_fr} de #{name_fr}"
        else
          organization_name = "#{type_name_en} of #{name_en}"
        end
      end

      if type == "RM" && code[0, 2] == "47"
        number = name_en.match(/No\. (\d+)\z/)[1]
      end

      output("csd:",
        code,
        name_en,
        name_fr,
        type,
        organization_name,
        number)
    end
  end

private

  def name(name, code)
    if name == "Resort Mun. Stan.B.-Hope R.-Bayv.-Cavend.-N.Rust."
      "Resort Municipality of Stanley Bridge-Hope River-Bayview-Cavendish-North Rustico"
    else
      value = name.
        squeeze(" ").                # Remove extra spaces, e.g. "Lot  1"
        sub(/ \(Part\)/, "").        # Remove "(Part)" e.g. "Flin Flon (Part)"
        sub(/(?<=No\.)(?=\S)/, " "). # Add a space after "No.", e.g. "Lesser Slave River No.124"
        sub(/, Labrador\z/, "").     # Remove subregion, e.g. "Cartwright, Labrador"
        sub(/ \(Labrador\)\z/, "")   # Remove subregion, e.g. "Charlottetown (Labrador)"

      # Expand "St." and "Ste." in New Brunswick and Quebec.
      if code[/\A(?:13|24)/]
        value.sub(/\bSt(e)?\./, 'Saint\1')
      else
        value
      end
    end
  end
end

CensusSubdivisions.new("ca_census_subdivisions.csv").run(ARGV)
