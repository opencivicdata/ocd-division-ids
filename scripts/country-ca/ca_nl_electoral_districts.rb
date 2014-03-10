#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Newfoundland and Labrador electoral district codes and names from assembly.nl.ca

class NL < Runner
  def names
    puts CSV.generate_line(%w(id name))
    # The shapefile from Elections Newfoundland and Labrador contains typos.
    # The only non-all-caps authoritative data source is the legislature.
    # @see http://www.elections.gov.nl.ca/elections/ElectoralBoundaries/index.html
    Nokogiri::HTML(open("http://www.assembly.nl.ca/members/cms/membersdistrict.htm")).css("#content table tr:gt(1) td:eq(1)").each do |td|
      name = td.text.normalize_space.gsub(" - ", "—") # m-dash
      output("province:nl/ed:", name, name)
    end
  end
end

NL.new("province-nl-electoral_districts.csv").run(ARGV)
