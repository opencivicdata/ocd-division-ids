#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Ontario electoral district codes and names from elections.on.ca

class ON < Runner
  def names
    puts CSV.generate_line(%w(id name))
    Nokogiri::HTML(open("http://fyed.elections.on.ca/fyed/en/list_page_en.jsp?show=all")).xpath("//table[@width=600]//a").sort_by{|a| a[:href]}.each do |a|
      output("province:on/ed:", a[:href][%r{=0*(\d+)\z}, 1], UnicodeUtils.downcase(a.text.sub('CHATHAM--KENT--', 'CHATHAM-KENT--').gsub('--', '—')).gsub(/\b(?!(?:and|s|the)\b)(\w)/){UnicodeUtils.upcase($1)})
    end
  end
end

ON.new("province-on-electoral_districts.csv").run(ARGV)
