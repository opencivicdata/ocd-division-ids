#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join('..', 'utils.rb'), __FILE__)

# Scrapes federal electoral district codes and names from elections.ca

require "nokogiri"

class CA < Runner
  @csv_filename = "ca_federal_electoral_districts.csv"
  @translatable = true

  def identifiers(language = "e")
    puts CSV.generate{|csv|
      # The most authoritative data is only available as HTML.
      Nokogiri::HTML(open("http://elections.ca/content.aspx?section=res&dir=cir/list&document=index&lang=#{language}")).css("tr").each do |tr|
        tds = tr.css("td")
        next if tds.empty?

        identifier = tds[0].text.gsub(/\D/, "")
        next unless identifier[/\A\d{5}\z/]

        # Statistics Canada uses the "FED" abbreviation.
        # @see http://www12.statcan.gc.ca/census-recensement/2011/ref/dict/geo025-eng.cfm
        csv << [
          "ocd-division/country:ca/fed:#{identifier}",
          tds[1].children[0].text.gsub(/[[:space:]]+/, " ").strip,
        ]
      end
    }
  end

  def translations
    identifiers("F")
  end
end

CA.new.run(ARGV)
