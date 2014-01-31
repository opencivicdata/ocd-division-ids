#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)
require File.expand_path(File.join("..", "classes.rb"), __FILE__)

# Scrapes municipal subdivision names from represent.opennorth.ca

require "json"

class MunicipalSubdivision < Runner
  @csv_filename = "ca_municipal_subdivisions.csv"
  @translatable = false

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
