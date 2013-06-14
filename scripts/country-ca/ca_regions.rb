#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes region codes and names from statcan.gc.ca

require "nokogiri"

class Regions < Runner
  @csv_filename = "ca_regions.csv"
  @translatable = true

  def names(language = "eng")
    Nokogiri::HTML(open("http://www.statcan.gc.ca/subjects-sujets/standard-norme/sgc-cgt/2011/sgc-cgt-intro-#{language}.htm")).css("ol:eq(2) li").each_with_index do |li,index|
      output("region:",
        index + 1,
        li.text)
    end
  end

  def names_fr
    names("fra")
  end
end

Regions.new.run(ARGV)
