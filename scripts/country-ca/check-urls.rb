#!/usr/bin/env ruby
# coding: utf-8

require "csv"

require "faraday"

directory = File.expand_path(File.join("..", "..", "..", "mappings", "country-ca-urls"), __FILE__)
Dir.entries(directory).each do |basename|
  if File.extname(basename) == ".csv"
    csv = CSV.read(File.join(directory, basename))

    csv.each do |id,url|
      type_id = id[/[^:]+\z/].to_i
      url_parse = URI.parse(url)

      begin
        response = Faraday.get(url) do |request|
          request.headers["User-Agent"] = "Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; WOW64; Trident/6.0)" # IE 10
        end

        if [301, 302, 303].include?(response.status)
          redirect_url = response.headers["location"]
          redirect_url_parse = URI.parse(redirect_url)

          unless url_parse.path.empty? && (url_parse.host == redirect_url_parse.host || redirect_url_parse.host.nil?)
            puts "#{response.status} #{type_id} #{url.ljust(70)} #{redirect_url}"
          end
        elsif response.status != 200
          puts "#{response.status} #{type_id} #{url}"
        end
      rescue Faraday::Error::ConnectionFailed, Faraday::Error::TimeoutError, Errno::ETIMEDOUT => e
        puts "ERR #{type_id} #{url.ljust(70)} #{e}"
      end
    end

    puts "Duplicates:"
    urls = csv.map(&:last)
    counts = Hash.new(0)
    urls.each do |url|
      counts[url] += 1
    end
    counts.each do |url,count|
      if count > 1
        puts url
      end
    end

    puts "With path:"
    urls.each do |url|
      unless URI.parse(url).path.empty?
        puts url
      end
    end
  end
end
