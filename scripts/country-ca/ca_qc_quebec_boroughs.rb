#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Quebec borough codes and names from ville.quebec.qc.ca

class Quebec < Runner
  def names
    ShapefileParser.new(
      "http://donnees.ville.quebec.qc.ca/Handler.ashx?id=2&f=SHP",
      "csd:2423027/borough:", {
        :id => "CODE",
        :name => lambda{|record| record.attributes["NOM"].gsub("–", "—")}, # n-dash, m-dash
        :sort_as => "CODE",
      }
    ).run
  end
end

Quebec.new("census_subdivision-quebec-boroughs.csv").run(ARGV)
