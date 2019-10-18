#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

class ONSchoolDistrict < Runner
  def names
    boundaries = []

    JSON.load(open("https://represent.opennorth.ca/boundary-sets/?name__contains=School%20Board%20boundaries"))["objects"].each do |boundary_set|
      boundaries += JSON.load(open("https://represent.opennorth.ca#{boundary_set["related"]["boundaries_url"]}?limit=0"))["objects"]
    end

    puts CSV.generate_line(%w(id name))

    boundaries.sort{|a,b|
      a = a["external_id"]
      b = b["external_id"]
      if a.to_i == b.to_i
        a.to_s <=> b.to_s
      else
        a.to_i <=> b.to_i
      end
    }.each{|boundary|
      output("province:on/school_district:", boundary["external_id"], boundary["name"])
    }
  end
end

ONSchoolDistrict.new("province-on-school_districts.csv").run(ARGV)
