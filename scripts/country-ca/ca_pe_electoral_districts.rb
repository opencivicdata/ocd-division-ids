#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Prince Edward Island electoral district codes and names from electionspei.ca

class PE < Runner
  def names
    puts CSV.generate_line(%w(id name))
    Nokogiri::HTML(URI.open("https://www.electionspei.ca/provincial-district-and-poll-maps")).css("h2 + p + ul li a").each do |li|
      number, name = li.text.normalize_space.match(/District (\d+) (.+)/)[1,2]
      output("province:pe/ed:", number, name.sub(" - ", "-")) # numbered list
    end
  end
end

PE.new("province-pe-electoral_districts.csv").run(ARGV)
