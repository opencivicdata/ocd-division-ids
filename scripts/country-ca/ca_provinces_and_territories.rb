#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes province and territory codes and names from Statistics Canada

class ProvincesAndTerritories < Runner
  def initialize(*args)
    super

    add_command({
      :name        => "names-fr",
      :description => "Prints a CSV of identifiers and French names and abbreviations",
      :output_path => "identifiers/country-ca/ca_provinces_and_territories-name_fr.csv",
    })
  end

  def names
    puts CSV.generate_line(%w(id name abbreviation abbreviation_fr sgc))
    rows("eng") do |row|
      output("#{row[:type]}:", row[:id], row[:name], row[:abbreviation], row[:abbreviation_fr], row[:sgc])
    end
  end

  def names_fr
    puts CSV.generate_line(%w(id name_fr))
    rows("fra") do |row|
      output("#{row[:type]}:", row[:id], row[:name])
    end
  end

private

  def rows(language)
    Nokogiri::HTML(open("http://www12.statcan.gc.ca/census-recensement/2016/ref/dict/tab/t1_8-#{language}.cfm")).xpath("//tr[@class]").each do |tr|
      tds = tr.xpath("./th|./td")
      abbreviation = tds[1].text.strip
      yield({
        :type => tds[3].text[0, 1] == "6" ? "territory" : "province",
        :id => tds[2].text, # @see https://www.canadapost.ca/tools/pg/manual/PGaddress-e.asp#1380608
        :name => tds[0].text.gsub(/\p{Space}/, ' '),
        :abbreviation => abbreviation[%r{\A(.+)/}, 1],
        :abbreviation_fr => abbreviation[%r{/(.+)\z}, 1],
        :sgc => tds[3].text,
      })
    end
  end
end

ProvincesAndTerritories.new("ca_provinces_and_territories.csv").run(ARGV)
