#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join('..', 'utils.rb'), __FILE__)

# Scrapes Alberta electoral district codes and names from altalis.com

class QC < Runner
  @csv_filename = "province-qc-electoral_districts.csv"
  @translatable = false # unilingual

  def identifiers
    CSV.parse(open("http://www.electionsquebec.qc.ca/documents/donnees-ouvertes/Liste_circonscriptions.txt"), :headers => true, :col_sep => ";").each do |row|
      puts CSV.generate_line([
        "ocd-division/country:ca/province:qc/ped:#{row["BSQ"]}",
        row["CIRCONSCRIPTION"],
      ])
    end
  end
end

QC.new.run(ARGV)

