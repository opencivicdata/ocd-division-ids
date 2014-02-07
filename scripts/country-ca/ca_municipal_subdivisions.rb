#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)
require File.expand_path(File.join("..", "classes.rb"), __FILE__)

# Scrapes municipal subdivision names from represent.opennorth.ca
# Municipalities may correspond to census divisions or census subdivisions.

require "json"
require "tempfile"
require "nokogiri"

class MunicipalSubdivision < Runner
  @csv_filename = "ca_municipal_subdivisions.csv"
  @translatable = false

  def initialize
    super

    add_command({
      :name        => "subdivisions",
      :description => "Prints a CSV of identifiers and booleans",
      :directory   => "mappings/country-ca-subdivisions",
    })
  end

  def names
    ignore = OpenCivicDataIdentifiers.read("country-ca/ca_provinces_and_territories").to_h.values << "Canada"

    items = []

    JSON.load(open("http://represent.opennorth.ca/boundary-sets/?limit=0"))["objects"].each do |boundary_set|
      domain = boundary_set["domain"]
      next if ignore.include?(domain)

      subsubdivision, census_subdivision, province_or_territory = domain.match(/\A(?:([^,]+), )?([^,]+), (NL|PE|NS|NB|QC|ON|MB|SK|AB|BC|YT|NT|NU)\z/)[1..3]

      # Ignore municipal subsubdivisions.
      unless subsubdivision
        matches = census_subdivisions.fetch(province_or_territory.downcase).fetch(census_subdivision)

        census_subdivision_id = if matches.size == 1
          matches[0][:id]
        else
          matches.find{|match| match[:type] == "CY"}[:id]
        end

        items << [census_subdivision_id, boundary_set]
      end
    end

    items.sort_by(&:first).each do |census_subdivision_id,boundary_set|
      ocd_type = boundary_set["name"].match(/ (borough|district|division|ward)s\z/)[1]

      JSON.load(open("http://represent.opennorth.ca#{boundary_set["related"]["boundaries_url"]}?limit=0"))["objects"].sort_by{|boundary|
        identifier(boundary)
      }.each{|boundary|
        output("csd:#{census_subdivision_id}/#{ocd_type}:",
          identifier(boundary),
          boundary["name"])
      }
    end
  end

  def subdivisions
    type_map = {
      "CT" => "CT",
      "M"  => "MÉ",
      "P"  => "PE",
      "V"  => "V",
      "VL" => "VL",
    }

    boroughs = [
      "Lévis",
      "Longueuil",
      "Montréal",
      "Québec",
      "Saguenay",
      "Sherbrooke",
    ]

    subdivisions = Hash.new("N")

    # http://www.novascotia.ca/snsmr/municipal/government/elections.asp
    # The spreadsheet and roo gems open the Excel file too slowly.
    Tempfile.open("data.xls") do |f|
      f.binmode
      open("http://www.novascotia.ca/snsmr/pdf/mun-municipal-election-results-2008-2012.xls") do |data|
        f.write(data.read)
      end
      sheet = `xls2csv #{f.path}`.split("\f")[4]

      type = nil
      name = nil
      CSV.parse(sheet) do |row|
        case row[0]
        when "Regional Municipalities"
          type = "RGM"
        when "Town"
          type = "T"
        when "Municipalities"
          type = "MD"
        end

        if row[0] && row[1] && row[0].strip != 'Municipality'
          next if row[0] == name
          name = row[0]

          value = row[0].sub(' (County)', '')
          identifier = nil

          if !row[0][/ \(County\)\z/]
            fingerprint = CensusSubdivisionNameMatcher.fingerprint("ns", value)
            identifier, _ = CensusSubdivisionNameMatcher.identifier_and_name(fingerprint)
            unless identifier
              fingerprint = ["ns", type, CensusSubdivisionName.new(value).normalize.fingerprint] * ":"
              identifier, _ = CensusSubdivisionNameTypeMatcher.identifier_and_name(fingerprint)
            end
          end
          unless identifier
            fingerprint = CensusDivisionNameMatcher.fingerprint("ns", value)
            identifier, _ = CensusDivisionNameMatcher.identifier_and_name(fingerprint)
          end

          subdivisions[identifier] = "Y"
        end
      end
    end

    Nokogiri::HTML(open("http://www.electionsquebec.qc.ca/francais/municipal/carte-electorale/liste-des-municipalites-divisees-en-districts-electoraux.php?index=1")).xpath('//div[@class="indente zone-contenu"]/div[@class="boite-grise"]//text()').each do |node|
      text = node.text.strip
      unless text.empty? || text == ", V"
        if boroughs.include?(text)
          name, type = text, "V"
        else
          name, type = text.match(/\A(.+), (.+)\z/)[1..2]
        end

        fingerprint = ["qc", type_map.fetch(type), CensusSubdivisionName.new(name).normalize.fingerprint] * ":"
        identifier, _ = CensusSubdivisionNameTypeMatcher.identifier_and_name(fingerprint)

        if identifier
          subdivisions[identifier] = "Y"
        elsif text != "L'Ange-Gardien, M" # two census subdivisions match
          raise fingerprint
        end
      end
    end

    # Sent an email to confirm with Directeur général des élections du Québec.
    %w(2403005 2438010 2446080).each do |identifier|
      subdivisions["ocd-division/country:ca/csd:#{identifier}"] = "Y"
    end

    OpenCivicDataIdentifiers.read("country-ca/ca_census_subdivisions").each do |identifier,_|
      type_id = identifier[/[^:]+\z/]
      case type_id[0, 2]
      when "12", "24"
        output("csd:", type_id.to_i, subdivisions[identifier])
      when "59"
        output("csd:", type_id.to_i, "N")
      end
    end
  end

private

  def census_subdivisions
    @census_subdivisions ||= {}.tap do |hash|
      OpenCivicDataIdentifiers.read("country-ca/ca_census_subdivisions").abbreviate!.each do |identifier,value|
        object = CensusSubdivisionIdentifier.new(identifier)
        key = object.province_or_territory_type_id
        hash[key] ||= {}
        hash[key][value] ||= []
        hash[key][value] << {:id => identifier, :type => object.census_subdivision_type}
      end
    end
  end

  def identifier(boundary)
    if boundary["external_id"].empty?
      boundary["name"]
    else
      boundary["external_id"].to_i
    end
  end
end

MunicipalSubdivision.new.run(ARGV)
