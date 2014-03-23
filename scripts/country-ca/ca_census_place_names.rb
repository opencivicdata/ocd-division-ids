#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Census place names from statcan.gc.ca

class CensusPlaceNames < Runner
  def names
    puts CSV.generate_line(%w(id name))

    # @see http://www5.statcan.gc.ca/bsolc/olc-cel/olc-cel?lang=eng&catno=12-571-X
    pdf = Tempfile.open("ca_census_place_names") do |f|
      f.binmode
      f.write(open("http://www.statcan.gc.ca/pub/12-571-x/12-571-x2011001-eng.pdf").read)
      f
    end

    header_re = /^\f?Table 8 Index of place names with associated census subdivision code, by province and territory, 2011(?: \((?:continued|concluded)\))?|^Place name.+|^ +type.+|^ +MIZ.+/
    footer_re = /^Standard Geographical Classification \(SGC\), 2011, Volume I +Statistics Canada +\d+|^\d+ +Statistics Canada +Standard Geographical Classification \(SGC\), 2011, Volume I/
    pages = []
    page = []

    # Group the lines into pages.
    maximum_line_length = 0
    `pdftotext -f 187 -l 525 -layout #{pdf.path} -`.split("\n").each do |line|
      # Skip headers.
      next if line[header_re]

      line_length = line.size
      if line_length > maximum_line_length
        maximum_line_length = line_length
      end

      if line[footer_re]
        pages << page
        page = []
      else
        page << line.rstrip
      end
    end

    column_divider_re = /(?<=    )\S/
    text = []

    # Transform the text of each page into a single column.
    pages.each do |page|
      index = maximum_line_length
      page.each do |line|
        # Skip new lines.
        next if line == ""

        match = line.match(column_divider_re, 63) # True indices first appear at 63.
        if match
          start = match.begin(0)
          if start < index
            index = start
          end
        end
      end

      column1 = []
      column2 = []
      page.each do |line|
        # Skip new lines.
        next if line == ""

        part = line[0...index].strip
        unless part.empty? || part[/^(Newfoundland and Labrador|Prince Edward Island|Nova Scotia|New Brunswick|Quebec|Ontario|Manitoba|Saskatchewan|Alberta|British Columbia|Yukon|Northwest Territories|Nunavut)(?: \((?:continued|concluded)\))?$/]
          column1 << part
        end
        part = line[index..-1]
        if part
          column2 << part.strip
        end
      end
      text += column1
      text += column2
    end

    buffer = []
    text.each do |line|
      row = buffer.empty? ? line : "#{buffer.join(" ")} #{line}"
      # Don't swallow "C" into the census subdivision type.
      match = row.match(/^(.+?(?:part C|partie C|Subd. C)?)(?: +(C|CC|CG|CN|COM|CT|CU|CV|CY|DM|HAM|ID|IGD|IM|IRI|LGD|LOT|M|MD|MÉ|MU|NH|NL|NO|NV|P|PE|RCR|RDA|RG|RGM|RM|RV|S-É|SA|SC|SÉ|SET|SG|SM|SNO|SV|T|TC|TI|TK|TL|TP|TV|V|VC|VK|VL|VN))? +(\d\d) +(\d\d) +(\d\d\d) +\d\d\d$/)
      if match
        name = match[1].gsub("’", "'").gsub(/(?<=\S-) /, '').squeeze(" ")
        # Skip census subdivisions and electoral districts.
        unless match[2] || name[/District électoral(?: d[eu']| de l[a']| des| municipal de)?$/]
          # @see http://www4.rncan.gc.ca/search-place-names/name.php
          if name[/^(.+?), (Aux|L[ae']|Les|The|Ferme expérimentale|Fort|Parc(?: industriel(?: métropolitain)?)?(?: d[eu]| des)?|Quartier|Secteur|Station de recherche(?: des)?|Station expérimentale de la|(?:County|Municipal District|Regional District|Specialized Municipality|United Counties|Village) of)$/]
            name = "#{$2} #{$1}"
          end
          output("csd:#{match[3..5].join}/place:", name, name)
        end
        buffer = []
      elsif buffer.size < 2
        buffer << line
      else
        raise buffer.inspect
      end
    end
  end
end

CensusPlaceNames.new("ca_census_place_names.csv").run(ARGV)
