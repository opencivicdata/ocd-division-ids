#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join('..', 'utils.rb'), __FILE__)

# Scrapes Newfoundland and Labrador electoral district codes and names from assembly.nl.ca

require "nokogiri"

class NL < Runner
  @csv_filename = "province-nl-electoral_districts.csv"
  @translatable = false # shapefile is unilingual

  def identifiers
    # The shapefile from Elections Newfoundland and Labrador contains typos.
    # The only non-all-caps authoritative data source is the legislature.
    # @see http://www.elections.gov.nl.ca/elections/ElectoralBoundaries/index.html
    Nokogiri::HTML(open("http://www.assembly.nl.ca/members/cms/membersdistrict.htm")).css("table:eq(1) tr:gt(1) td:eq(1)").each do |td|
      name = td.text.gsub(/\p{Space}+/, ' ').strip
      puts CSV.generate_line([
        "ocd-division/country:ca/province:nl/ped:#{name.parameterize}", # shapefile has no identifiers
        name.gsub(' - ', '—'), # m-dash
      ])
    end
  end
end

NL.new.run(ARGV)
