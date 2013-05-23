#!/usr/bin/env ruby
# coding: utf-8

# Scrapes federal electoral district codes and names from elections.ca

require "rubygems"
require "bundler/setup"

require "csv"
require "open-uri"
require "optparse"

require "nokogiri"

opts = OptionParser.new do |opts|
  opts.program_name = "ca_federal_electoral_districts.rb"
  opts.banner = <<-EOS
Usage: #{opts.program_name} COMMAND

Commands:
  identifiers  Prints a CSV of identifiers and English names, e.g.:
               #{opts.program_name} identifiers > identifiers/country-ca/ca_federal_electoral_districts.csv
  mappings     Prints a CSV of identifiers and French names, e.g.:
               #{opts.program_name} mappings > mappings/country-ca-fr/ca_federal_electoral_districts.csv
  EOS

  opts.separator ""
  opts.separator "Options:"
  opts.on_tail("-h", "--help", "Display this screen") do
    puts opts
    exit
  end
end

opts.parse!

command = ARGV.shift

case command
when "identifiers"
  lang = "e"
when "mappings"
  lang = "f"
when nil
  puts opts
  exit
else
  puts %(`#{command}` is not a #{opts.program_name} command. See `#{opts.program_name} --help` for a list of available commands.)
  exit
end

puts CSV.generate{|csv|
  # The most authoritative data is only available as HTML.
  Nokogiri::HTML(open("http://elections.ca/content.aspx?section=res&dir=cir/list&document=index&lang=#{lang}")).css("tr").each do |tr|
    tds = tr.css("td")
    next if tds.empty?

    code = tds[0].text.gsub(/\D/, "")
    next unless code[/\A\d{5}\z/]

    # Statistics Canada uses the "FED" abbreviation.
    # @see http://www12.statcan.gc.ca/census-recensement/2011/ref/dict/geo025-eng.cfm
    csv << [
      "ocd-division/country:ca/fed:#{code}",
      tds[1].children[0].text.gsub(/[[:space:]]+/, " ").strip,
    ]
  end
}
