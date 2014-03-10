#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes region codes and names from statcan.gc.ca

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
    rows("name", "eng")
  end

  def names_fr
    rows("name_fr", "fra")
  end

private

  def rows(column_name, language)
    puts CSV.generate_line(['id', column_name])
    # The regions appear in the same order in both languages.
    Nokogiri::HTML(open("http://www.statcan.gc.ca/subjects-sujets/standard-norme/sgc-cgt/2011/sgc-cgt-intro-#{language}.htm")).css("ol:eq(2) li").each_with_index do |li,index|
      output("region:", index + 1, li.text) # the number is the first digit of any SGC code
    end
  end
end

Regions.new("ca_regions.csv").run(ARGV)
