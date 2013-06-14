#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes province and territory codes and names from statcan.gc.ca

require "nokogiri"

class ProvincesAndTerritories < Runner
  @csv_filename = "ca_provinces_and_territories.csv"
  @translatable = true

  def initialize
    super

    add_command({
      :name        => "abbreviations",
      :description => "Prints a CSV of identifiers and canonical census abbreviations",
      :directory   => "mappings/country-ca-abbr",
    })

    add_command({
      :name        => "abbreviations-fr",
      :description => "Prints a CSV of identifiers and French census abbreviations",
      :directory   => "mappings/country-ca-abbr-fr",
    })

    add_command({
      :name        => "sgc-codes",
      :description => "Prints a CSV of identifiers and canonical Standard Geographical Classification (SGC) codes",
      :directory   => "mappings/country-ca-sgc",
    })
  end

  def names(language = "eng")
    rows(language).each do |row|
      output("#{row[:type]}:",
        row[:identifier],
        row[:name])
    end
  end

  def names_fr
    names("fra")
  end

  def abbreviations(language = "eng")
    rows(language).each do |row|
      output("#{row[:type]}:",
        row[:identifier],
        row[:abbreviation])
    end
  end

  def abbreviations_fr
    abbreviations("fra")
  end

  def sgc_codes
    rows.each do |row|
      output("#{row[:type]}:",
        row[:identifier],
        row[:sgc_code])
    end
  end

private

  def rows(language = "eng")
    # Also available as table in larger document.
    # @see http://www.statcan.gc.ca/subjects-sujets/standard-norme/sgc-cgt/2011/sgc-cgt-intro-eng.htm#a4-2
    Nokogiri::HTML(open("http://www12.statcan.gc.ca/census-recensement/2011/ref/dict/table-tableau/table-tableau-8-#{language}.cfm")).css("tbody tr").map do |tr|
      tds = tr.css("td")
      {
        :name         => tds[0].text,
        :abbreviation => tds[1].text[%r{\A(.+?)/}, 1],
        # @see http://www.canadapost.ca/tools/pg/manual/PGaddress-e.asp#1380608
        :identifier   => tds[2].text,
        :sgc_code     => tds[3].text,
        :type         => tds[3].text[0, 1] == "6" ? "territory" : "province",
      }
    end
  end
end

ProvincesAndTerritories.new.run(ARGV)
