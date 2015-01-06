#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)
require File.expand_path(File.join("..", "classes.rb"), __FILE__)

MUNICIPAL_ASSOCIATIONS = [
  "Alberta Association of Municipal Districts and Counties",
  "Alberta Urban Municipalities Association",
  "Union of British Columbia Municipalities",
  "Association des municipalités bilingues du Manitoba",
  "Association of Manitoba Municipalities",
  "Association francophone des municipalités du Nouveau-Brunswick",
  "Cities of New Brunswick Association",
  "Union of Municipalities of New Brunswick",
  "Union of Nova Scotia Municipalities",
  "Municipalities Newfoundland and Labrador",
  "Northwest Territories Association of Communities",
  "Nunavut Association of Municipalities",
  "Association of Municipalities of Ontario",
  "Federation of Prince Edward Island Municipalities",
  "Fédération Québécoise des Municipalités",
  "Union des Municipalités du Québec",
  "Saskatchewan Association of Rural Municipalities",
  "Saskatchewan Urban Municipalities Association",
  "Association of Yukon Communities",
]

# Override the FCM URL.
URL_OVERRIDE = {
  # http://www.fcm.ca/home/about-us/membership/our-members.htm?prov=NL
  1003026 => 'http://www.ramea.ca', # truncate URL
  1010032 => 'http://www.labradorwest.com/default.php?ac=changeSite&sid=1', # distinguish subdivisions
  1010034 => 'http://www.labradorwest.com/default.php?ac=changeSite&sid=2', # distinguish subdivisions
  # http://www.fcm.ca/home/about-us/membership/our-members.htm?prov=QC
  2446058 => 'http://www.sutton.ca', # truncate URL
  2459020 => 'http://www.ville.varennes.qc.ca', # incorrect URL
  # http://www.fcm.ca/home/about-us/membership/our-members.htm?prov=ON
  3530035 => 'http://www.woolwich.ca', # truncate URL
  3559019 => 'http://www.emo.ca', # truncate URL
  # http://www.fcm.ca/home/about-us/membership/our-members.htm?prov=MB
  4601057 => 'http://lacdubonnet.com/main.asp?fxoid=FXMenu,1&cat_ID=1&sub_ID=16', # distinguish subdivisions
  4601060 => 'http://lacdubonnet.com/main.asp?fxoid=FXMenu,2&cat_ID=1&sub_ID=17', # distinguish subdivisions
  4603074 => 'http://townofcarman.com', # distinguish subdivisions
  4603072 => 'http://rmofdufferin.com', # distinguish subdivisions
  4605061 => 'http://www.hartney.ca/main.asp?id_menu=44&parent_id=1', # distinguish subdivisions
  4605063 => 'http://www.hartney.ca/main.asp?id_menu=42&parent_id=1', # distinguish subdivisions
  4615055 => 'http://www.birtle.ca', # incorrect URL
  4616002 => 'http://www.rossburn.ca', # incorrect URL
  4616007 => 'http://www.rossburn.ca', # incorrect URL
  # http://www.fcm.ca/home/about-us/membership/our-members.htm?prov=SK
  4703028 => 'http://www.willowbunch.ca/rm42', # distinguish subdivisions
  4706001 => 'http://myrm.ca/126/', # distinguish subdivisions
  4706053 => 'http://www.lumsden.ca/rm189/', # distinguish subdivisions
  4707031 => 'http://www.chaplin.ca', # incorrect URL
  4711052 => 'http://www.young.ca/rm-morris.htm', # distinguish subdivisions
  4711076 => 'http://www.townofcolonsay.ca/rural-municipality/', # distinguish subdivisions
  4711079 => 'http://www.townofcolonsay.ca', # distinguish subdivisions
  4714091 => 'http://www.villageoflove.ca', # incorrect URL
  4714092 => 'http://www.choiceland.ca', # incorrect URL
  4716046 => 'http://www.rmofshellbrook.com', # incorrect URL
  # http://www.fcm.ca/home/about-us/membership/our-members.htm?prov=AB
  4813010 => 'http://summervillageofsilversands.com', # incorrect URL
  4813015 => 'http://summervillageofsouthview.com', # incorrect URL
  # http://www.fcm.ca/home/about-us/membership/our-members.htm?prov=BC
  5915025 => 'http://www.burnaby.ca', # multiple redirects
  5924025 => 'http://www.villageofgoldriver.ca', # incorrect URL
  # http://www.fcm.ca/home/about-us/membership/our-members.htm?prov=NT
  6105003 => 'http://enterprise.lgant.ca', # truncate URL
  # http://www.fcm.ca/home/about-us/membership/our-members.htm?prov=NU
  6204003 => 'http://www.city.iqaluit.nu.ca', # truncate URL
}

class Redirection < StandardError; end

def clean_url(url, other = nil)
  parts = URI.parse(url)
  if parts.host.nil?
    other = URI.parse(other)
    parts.scheme = other.scheme
    parts.host = other.host
    unless parts.path[0] == "/"
      parts.path.insert(0, "/")
    end
  end
  if parts.path == "/"
    parts.path = ""
  end
  parts.to_s
end

# province_or_territory_map.call([nil, "Yukon Territory"]) # "Yukon"
province_or_territory_map = lambda do |(_,name)|
  # Effective October 20, 2008, the name "Yukon Territory" became "Yukon". The
  # name "Nunavut" was never "Nunavut Territory". The English name is "Quebec".
  # @see http://www.statcan.gc.ca/subjects-sujets/standard-norme/sgc-cgt/notice-avis/sgc-cgt-01-eng.htm
  name.sub(" Territory", "").tr("é", "e")
end

provinces_and_territories = OpenCivicDataIdentifiers.read("country-ca/ca_provinces_and_territories")
provinces_and_territories_hash = Lycopodium.new(provinces_and_territories, province_or_territory_map).value_to_fingerprint.invert

failures = []
unmatched = []

puts CSV.generate_line(%w(id url))
Nokogiri::HTML(open("http://www.fcm.ca/home/about-us/membership/our-members.htm")).css("tbody tr").each do |tr|
  fingerprint = province_or_territory_map.call([nil, tr.at_css("td:eq(2)").text])
  province_or_territory_type_id = provinces_and_territories_hash.fetch(fingerprint).first[/[^:]+\z/]

  Nokogiri::HTML(open(tr.at_css("a")[:href])).css("ul.membership li").each do |li|
    a = li.at_css("a")
    next unless a && a[:href]["@"].nil?

    value = li.text.strip
    next if MUNICIPAL_ASSOCIATIONS.include?(value)

    fingerprint = CensusSubdivisionNameMatcher.fingerprint(province_or_territory_type_id, value)
    census_subdivision = CensusSubdivisionNameMatcher.identifier_and_name(fingerprint)
    unless census_subdivision
      fingerprint = CensusSubdivisionNameTypeMatcher.fingerprint(province_or_territory_type_id, value)
      census_subdivision = CensusSubdivisionNameTypeMatcher.identifier_and_name(fingerprint)
    end

    # If we have a match, do a lot of work to determine the best URL.
    if census_subdivision
      type_id = census_subdivision.first[/[^:]+\z/].to_i
      if URL_OVERRIDE.key?(type_id)
        url = URL_OVERRIDE[type_id]
      else
        url = clean_url(a[:href].sub(%r{\A(http://)(?:http:/)?/}, '\1'))
      end

      parsed = URI.parse(url)

      attempts = []
      begin
        attempts << url

        response = Faraday.get(url) do |request|
          request.headers["User-Agent"] = "Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; WOW64; Trident/6.0)" # IE 10
        end

        if [301, 302, 303].include?(response.status)
          new_url = clean_url(response.headers["location"], url)
          new_parsed = URI.parse(new_url)

          # If it redirects to a URL without a path, redirect from a URL with
          # a path, or redirects to a path on a new domain, use the new URL.
          # If it redirects from a URL without a path to a URL with a path on
          # the same domain, use the old URL.
          if new_parsed.path.empty? || !parsed.path.empty? || parsed.host != new_parsed.host
            url = new_url
            parsed = URI.parse(url)
            raise Redirection
          end
        elsif response.status == 200 && !parsed.path.empty?
          new_parsed = parsed.dup
          new_parsed.path = ""

          # If the path is a root index page, remove the path.
          if parsed.path[%r{\A/(?:en/|fr/)?(?:index.(?:aspx?|cfm|html?|jsp|php))?\z}]
            url = new_parsed.to_s
          # If the TLD redirects to the URL, use the TLD.
          else
            response = Faraday.get(new_parsed.to_s)
            if response.status == 200
              meta = Nokogiri::HTML(response.body).at_css('meta[http-equiv="REFRESH"],meta[http-equiv="refresh"]')
              if meta && meta['content'][/url=(.+)/i, 1] == url
                url = new_parsed.to_s
              end
            elsif [301, 302].include?(response.status) && [url, parsed.path].include?(response.headers["location"])
              url = new_parsed.to_s
            end
          end
        elsif response.status != 200
          failures << [type_id, census_subdivision.last, url, response.status]
          next
        end
      rescue Redirection
        # Can't retry outside of rescue.
        if attempts.include?(url)
          $stderr.puts "Redirection loop #{url}"
        else
          retry
        end
      rescue Faraday::Error::TimeoutError, Errno::ETIMEDOUT
        # pass
      rescue Faraday::Error::ConnectionFailed, Zlib::BufError, Zlib::DataError, URI::InvalidURIError => e
        failures << [type_id, census_subdivision.last, url, "#{e.class.name} #{e.message}"]
        next
      end

      output("csd:", type_id, url)
    else
      unmatched << "#{value.ljust(65)} #{fingerprint}" if fingerprint
    end
  end
end

$stderr.puts
$stderr.puts "Unmatched:"
$stderr.puts unmatched
$stderr.puts
$stderr.puts "Failures:"
failures.each do |type_id,name,url,message|
  $stderr.puts "#{type_id} #{name.ljust(25)} #{url.ljust(60)} #{message}"
end
