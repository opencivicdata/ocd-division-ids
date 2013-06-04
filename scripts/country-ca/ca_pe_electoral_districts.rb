#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join('..', 'utils.rb'), __FILE__)

# Scrapes Prince Edward Island electoral district codes and names from electionspei.ca

require "nokogiri"

class PE < Runner
  @csv_filename = "province-pe-electoral_districts.csv"

  def identifiers
    puts CSV.generate{|csv|
      # The shapefile from gov.pe.ca does not have one feature per district. The
      # KML file from electionspei.ca has district names in all-caps.
      # @see http://www.gov.pe.ca/gis/index.php3?number=77868&lang=E
      # @see http://www.electionspei.ca/provincial/districts/index.php
      Nokogiri::HTML(open("http://www.electionspei.ca/provincial/districts/index.php")).css("ol li").each_with_index do |li,index|
        name = li.text.gsub(/\p{Space}+/, ' ').strip
        next if name.empty?

        csv << [
          "ocd-division/country:ca/province:pe/ped:#{index + 1}",
          name.sub(' - ', '-'), # hyphen
        ]
      end
    }
  end
end

PE.new.run(ARGV)
