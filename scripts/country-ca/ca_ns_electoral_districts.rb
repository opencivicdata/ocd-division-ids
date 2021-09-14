#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

# Scrapes Nova Scotia electoral district codes and names from electionsnovascotia.ca

class NS < Runner
  # @see https://electionsnovascotia.ca/content/maps-and-boundary-files
  def names
    ShapefileParser.new(
      "https://www.electionsnovascotia.ca/sites/default/files/NS_2019ED_Bnds.zip",
      "province:ns/ed:", {
        :id => "ED_NO",
        :name => "ED_NAME",
      }
    ).run
  end
end

NS.new("province-ns-electoral_districts.csv").run(ARGV)
