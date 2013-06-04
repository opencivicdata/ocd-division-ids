#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join('..', 'utils.rb'), __FILE__)

# Scrapes Manitoba electoral district codes and names from gov.mb.ca

require "nokogiri"

class MB < Runner
  @csv_filename = "province-mb-electoral_districts.csv"
  @translatable = true

  def identifiers(infix = "")
    puts CSV.generate{|csv|
      # The shapefile from the Manitoba Land Initiative requires authentication
      # and is unilingual English, like most data sources. It appears only the
      # legislature translates district names.
      # @see https://mli2.gov.mb.ca/adminbnd/index.html
      Nokogiri::HTML(open("http://www.gov.mb.ca/hansard/members/constituency#{infix}.html")).css("table.text tr:gt(1) td:eq(1)").each do |td|
        name = td.text.gsub(/\p{Space}+/, ' ').strip
        csv << [
          "ocd-division/country:ca/province:mb/ped:#{name.parameterize}", # shapefile has no identifiers
          name,
        ]
      end
    }
  end

  def translations
    identifiers(".fr")
  end
end

MB.new.run(ARGV)
