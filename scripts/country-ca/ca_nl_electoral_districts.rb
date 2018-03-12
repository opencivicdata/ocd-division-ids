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
    coder = HTMLEntities.new
    names = open('http://www.assembly.nl.ca/js/members-index.js').read.scan(/district: '(.+)'/).map do |district|
      coder.decode(district[0]).gsub(" - ", "—") # m-dash
    end
    names.sort.each do |name|
      output("province:nl/ed:", name, name)
    end
  end
end

NL.new("province-nl-electoral_districts.csv").run(ARGV)
