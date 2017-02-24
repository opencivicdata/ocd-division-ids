#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes region codes and names from Statistics Canada

class Regions < Runner
  def initialize(*args)
    super

    add_command({
      :name        => "names-fr",
      :description => "Prints a CSV of identifiers and French names",
      :output_path => "identifiers/country-ca/ca_regions-name_fr.csv",
    })
  end

  def names
    rows("name", "")
  end

  def names_fr
    rows("name_fr", "_f")
  end

private

  def rows(column_name, language)
    puts CSV.generate_line(['id', column_name])
    # The regions appear in the same order in both languages.
    Nokogiri::HTML(open("http://www23.statcan.gc.ca/imdb/p3VD#{language}.pl?Function=getVD&TVD=314300")).xpath("//tbody/tr").each do |tr|
      output("region:", tr.at_xpath('./th[1]/a//text()').text, tr.at_xpath('./td[1]').text) # the number is the first digit of any SGC code
    end
  end
end

Regions.new("ca_regions.csv").run(ARGV)
