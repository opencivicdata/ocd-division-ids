#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Quebec district codes and names from ville.quebec.qc.ca

class Quebec < Runner
  def names
    ShapefileParser.new(
      "http://donnees.ville.quebec.qc.ca/Handler.ashx?id=43&f=SHP",
      "csd:2423027/district:", {
        :id => "CODE",
        :name => "NOM",
        :sort_as => "CODE",
      },
      lambda do |record|
        record.attributes.fetch("DATE_FIN") == Date.new(2017, 11, 5)
      end,
    ).run
  end
end

Quebec.new("census_subdivision-quebec-districts.csv").run(ARGV)
