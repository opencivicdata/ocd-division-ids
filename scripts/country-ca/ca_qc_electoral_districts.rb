#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Alberta electoral district codes and names from altalis.com

class QC < Runner
  @csv_filename = "province-qc-electoral_districts.csv"
  @translatable = false # unilingual

  def identifiers
    # No official government source has a full list of identifiers and names
    # with the correct dashes.
    CSV.parse(open("http://www.electionsquebec.qc.ca/documents/donnees-ouvertes/Liste_circonscriptions.txt"), :headers => true, :col_sep => ";").each do |row|
      output("province:qc/ed:",
        row["BSQ"],
        row["CIRCONSCRIPTION"])
    end
  end
end

QC.new.run(ARGV)
