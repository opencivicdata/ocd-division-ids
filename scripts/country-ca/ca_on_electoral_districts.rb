#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join('..', 'utils.rb'), __FILE__)

# Scrapes Ontario electoral district codes and names from elections.on.ca

require "nokogiri"

class ON < Runner
  @csv_filename = "province-on-electoral_districts.csv"
  @translatable = true

  def identifiers(index = 1)
    # The shapefile from elections.on.ca has district names in all-caps.
    # @see http://www.elections.on.ca/en-CA/Tools/ElectoralDistricts/PDEDS.htm
    Nokogiri::HTML(open("http://www.elections.on.ca/en-CA/Tools/ElectoralDistricts/EDNames.htm")).css("table table tr:gt(1)").each do |tr|
      texts = tr.css('td').map do |td|
        # OCD removes leading zeros.
        td.text.sub(/^0+/, '').gsub(/\p{Space}+/, ' ').strip
      end

      puts CSV.generate_line([
        "ocd-division/country:ca/province:on/ped:#{texts[0]}",
        texts[index].sub(/\.(?=\S)/, '. '), # add missing space
      ])
    end
  end

  def translations
    identifiers(2)
  end
end

ON.new.run(ARGV)
