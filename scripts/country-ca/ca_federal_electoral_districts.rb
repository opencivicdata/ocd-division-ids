#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes federal electoral district codes and names from elections.ca

class CA < Runner
  def initialize(*args)
    super

    add_command({
      :name        => "names-fr",
      :description => "Prints a CSV of identifiers and French names",
      :output_path => "identifiers/country-ca/ca_federal_electoral_districts-name_fr.csv",
    })
  end

  def names
    rows("name", "e")
  end

  def names_fr
    rows("name_fr", "F")
  end

private

  def rows(column_name, language)
    puts CSV.generate_line(['id', column_name])
    # The most authoritative data is only available as HTML.
    Nokogiri::HTML(open("http://elections.ca/content.aspx?section=res&dir=cir/list&document=index&lang=#{language}")).css("tr").each do |tr|
      tds = tr.css("td")
      next if tds.empty? # if th tags

      identifier = tds[0].text.gsub(/\D/, "")
      next unless identifier[/\A\d{5}\z/] # name changes and totals

      # "Saint Boniface" is inconsistent with other district names in Manitoba,
      # "Charleswood–St. James–Assiniboia" and "Kildonan–St. Paul".
      output("ed:", identifier, tds[1].children[0].text.normalize_space)
    end
  end
end

CA.new("ca_federal_electoral_districts.csv").run(ARGV)
