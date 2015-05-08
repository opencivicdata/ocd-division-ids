#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes federal electoral district codes and names from elections.ca

class CA < Runner
  def names
    puts CSV.generate_line(["id", "name", "name_fr", "validFrom", "validThrough"])

    names_en = rows("e")
    names_fr = rows("F")

    ShapefileParser.new(
      "http://ftp2.cits.rncan.gc.ca/pub/geobase/official/fed_cf/shp_eng/fed_cf_CA_2_1_shp_en.zip",
      "ed:", {
        :id => "FEDNUM",
        :name => "ENNAME",
        :name_fr => "FRNAME",
        :sort_as => "FEDNUM",
        :validFrom => lambda{|record| names_en.delete(record.attributes["FEDNUM"].to_s) ? "" : "2015-10-19"},
        :validThrough => lambda{|record| ""},
      }
    ).run(:write_headers => false)

    names_en.each do |identifier,name|
      output("ed:", identifier, name, names_fr[identifier], "", "2015-10-18")
    end
  end

private

  def rows(language)
    divisions = {}

    # The most authoritative data is only available as HTML.
    Nokogiri::HTML(open("http://elections.ca/content.aspx?section=res&dir=cir/list&document=index&lang=#{language}")).css("tr").each do |tr|
      tds = tr.css("td")
      next if tds.empty? # if th tags

      identifier = tds[0].text.gsub(/\D/, "")
      next unless identifier[/\A\d{5}\z/] # name changes and totals

      name = tds[1].children[0].text.normalize_space.gsub("–", "—") # n-dash, m-dash
      if name == "Western Arctic"
        name = language == "e" ? "Northwest Territories" : "Territoires du Nord-Ouest"
      end

      # "Saint Boniface" is inconsistent with other district names in Manitoba,
      # "Charleswood–St. James–Assiniboia" and "Kildonan–St. Paul".
      divisions[identifier] = name
    end

    divisions
  end
end

CA.new("ca_federal_electoral_districts.csv").run(ARGV)
