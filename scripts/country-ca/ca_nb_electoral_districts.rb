#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join('..', 'utils.rb'), __FILE__)

# Scrapes New Brunswick electoral district codes and names from gnb.ca

class NB < Runner
  @csv_filename = "province-nb-electoral_districts.csv"
  @translatable = true

  def identifiers(language = "E")
    # Also available as inconsistently formatted lists.
    # @see http://www2.gnb.ca/content/gnb/fr/contacts/dept_renderer.154.html#structure
    ShapefileParser.new(
      "http://www.gnb.ca/elections/pdf/2010PEDMaps/NB_Electoral_Districts.zip",
      "ocd-division/country:ca/province:nb/ped:", {
        :identifier => "PED_Num",
        :name => "PED_Name_#{language}",
        :default => "PED_Name_E",
      }
    ).run
  end

  def translations
    identifiers("F")
  end
end

NB.new.run(ARGV)
