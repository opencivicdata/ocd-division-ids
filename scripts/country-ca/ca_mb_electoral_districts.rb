#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Manitoba electoral district codes and names from gov.mb.ca

class MB < Runner
  def names
    # Sort the French names in the same order as the English.
    names_fr = rows(".fr").sort_by do |name|
      case name.strip
      when "Chemin-Dawson"
        "Dawson Trail"
      when "Entre-les-Lacs"
        "Interlake"
      when "Le Pas"
        "The Pas"
      when "Mont-Riding"
        "Riding Mountain"
      when "Rivière-Seine"
        "Seine River"
      when "Saint-Boniface"
        "St. Boniface"
      when "Saint-Norbert"
        "St. Norbert"
      when "Saint-Vital"
        "St. Vital"
      else
        name.strip
      end
    end

    puts CSV.generate_line(%w(id name name_fr))
    rows("").each_with_index do |name,index|
      output("province:mb/ed:", name, name, names_fr[index])
    end
  end

  def names_2018
    args = [
      "province:mb/ed:",
      {
        :id => lambda{|record| "#{record.attributes["ED"].force_encoding("utf-8").encode("utf-8")}-2018"},
        :name => lambda{|record| record.attributes["ED"].force_encoding("utf-8").encode("utf-8")},
        :validFrom => lambda{|record| "2019-09-10"},
      },
      nil,
      {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE},
    ]

    ShapefileParser.new(
      "https://www.electionsmanitoba.ca/downloads/2018_Final_ED_Manitoba_Public_Urban.zip", *args
    ).run
    ShapefileParser.new(
      "https://www.electionsmanitoba.ca/downloads/2018_Final_ED_Winnipeg_Public_Urban.zip", *args
    ).run(write_headers: false)
  end

private

  def rows(infix)
    # The shapefile from the Manitoba Land Initiative requires authentication
    # and is unilingual English. It seems only the legislature translates names.
    # @see https://mli2.gov.mb.ca/adminbnd/index.html
    Nokogiri::HTML(open("http://www.gov.mb.ca/legislature/members/mla_list_constituency#{infix}.html")).xpath("//div[@class='calendar_wrap']/table[1]//td[1]").map do |td|
      td.text.normalize_space
    end
  end
end

MB.new("province-mb-electoral_districts.csv").run(ARGV)
