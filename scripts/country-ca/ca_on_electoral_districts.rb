#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Ontario electoral district codes and names from elections.on.ca

class ON < Runner
  def names
    puts CSV.generate_line(%w(id name name_fr))
    # The shapefile from elections.on.ca has district names in all-caps.
    # @see http://www.elections.on.ca/en-CA/Tools/ElectoralDistricts/PDEDS.htm
    Nokogiri::HTML(open("http://www.elections.on.ca/en-CA/Tools/ElectoralDistricts/EDNames.htm")).css("table table tr:gt(1)").each do |tr|
      texts = tr.css("td").map do |td|
        td.text.normalize_space.sub(/\.(?=\S)/, ". ").sub(/(?<=Lennox)(?=and)/, " ") # add missing space
      end

      output("province:on/ed:", texts[0], texts[1], texts[2])
    end
  end
end

ON.new("province-on-electoral_districts.csv").run(ARGV)
