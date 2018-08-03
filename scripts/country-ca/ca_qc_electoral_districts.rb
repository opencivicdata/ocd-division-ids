#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Quebec electoral district codes and names from electionsquebec.qc.ca

class QC < Runner
  def initialize(*args)
    super

    add_command({
      :name        => "names-2017",
      :description => "Prints a CSV of identifiers and English names",
      :output_path => "identifiers/country-ca/province-qc-electoral_districts-2017.csv",
    })
  end

  def names
    puts CSV.generate_line(%w(id name))
    # No official government source has a full list of identifiers and names
    # with the correct dashes.
    CSV.parse(open("http://www.electionsquebec.qc.ca/documents/donnees-ouvertes/Liste_circonscriptions.txt").read.force_encoding("windows-1252").encode("utf-8"), :headers => true, :col_sep => ";").each do |row|
      output("province:qc/ed:", row["BSQ"], row["CIRCONSCRIPTION"])
    end
  end

  def names_2017
    ShapefileParser.new(
      "https://www.electionsquebec.qc.ca/documents/zip/circonscriptions_electorales_2017_shapefile.zip",
      "province:qc/ed:", {
        :id => lambda{|record| "#{record.attributes["CO_CEP"]}-2017"},
        :name => "NM_CEP",
        :validFrom => lambda{|record| "2018-10-01"},
      }
    ).run
  end
end

QC.new("province-qc-electoral_districts.csv").run(ARGV)
