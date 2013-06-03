#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join('..', 'utils.rb'), __FILE__)

# Scrapes New Brunswick electoral district codes and names from gnb.ca

require "zip/zip"
require "dbf"

class NB < Runner
  @program_name = "ca_nb_electoral_districts.rb"
  @csv_filename = "province-nb-electoral_districts.csv"

  def identifiers(language = "E")
    Zip::ZipFile.open(open("http://www.gnb.ca/elections/pdf/2010PEDMaps/NB_Electoral_Districts.zip")) do |zipfile|
      entry = zipfile.entries.find{|entry| File.extname(entry.name) == ".dbf"}
      if entry
        puts CSV.generate{|csv|
          DBF::Table.new(StringIO.new(zipfile.read(entry))).sort_by do |record|
            record.attributes.fetch("PED_Num")
          end.each do |record|
            name = record.attributes.fetch("PED_Name_#{language}")
            if name.empty?
              name = record.attributes.fetch("PED_Name_E")
            end
            csv << [
              "ocd-division/country:ca/province:nb/ped:#{record.attributes.fetch("PED_Num")}",
              name,
            ]
          end
        }
      else
        raise "DBF file not found!"
      end
    end
  end

  def mappings
    identifiers("F")
  end
end

NB.new.run(ARGV)
