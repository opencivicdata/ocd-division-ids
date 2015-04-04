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
