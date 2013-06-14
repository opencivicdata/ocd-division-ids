#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Prince Edward Island electoral district codes and names from electionspei.ca

require "nokogiri"

class PE < Runner
  @csv_filename = "province-pe-electoral_districts.csv"
  @translatable = false # shapefile is unilingual

  def names
    # The shapefile from gov.pe.ca does not have one feature per district. The
    # KML file from electionspei.ca has district names in all-caps.
    # @see http://www.gov.pe.ca/gis/index.php3?number=77868&lang=E
    # @see http://www.electionspei.ca/provincial/districts/index.php
    Nokogiri::HTML(open("http://www.electionspei.ca/provincial/districts/index.php")).css("ol li").each_with_index do |li,index|
      name = li.text.gsub(/\p{Space}+/, " ")
      output("province:pe/ed:",
        index + 1,
        name.sub(" - ", "-")) # hyphen
    end
  end
end

PE.new.run(ARGV)
