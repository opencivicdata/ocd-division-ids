#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

require "faraday"
require "lycopodium"
require "nokogiri"
require "unicode_utils/upcase"

require File.expand_path(File.join("..", "classes.rb"), __FILE__)

province_or_territory_map = lambda do |(_,name)|
  # Effective October 20, 2008, the name "Yukon Territory" became "Yukon". The
  # name "Nunavut" was never "Nunavut Territory". The English name is "Quebec".
  # @see http://www.statcan.gc.ca/subjects-sujets/standard-norme/sgc-cgt/notice-avis/sgc-cgt-01-eng.htm
  name.sub(" Territory", "").tr("é", "e")
end

provinces_and_territories = OpenCivicDataIdentifiers.read("country-ca/ca_provinces_and_territories")
provinces_and_territories_hash = Lycopodium.new(provinces_and_territories, province_or_territory_map).value_to_fingerprint.invert

# `value` is either a OCD identifier or a province or territory type ID. `name`
# is a either an official or a scraped census subdivision name.
census_subdivision_map = lambda do |(value,name)|
  value = CensusSubdivisionName.identifier_from_name(name) || value
  name = CensusSubdivisionName.new(name).normalize
  if value[/\Aocd-division/]
    identifier = CensusSubdivisionIdentifier.new(value)
    [identifier.province_or_territory_type_id, name.fingerprint]
  else
    return nil if CensusDivisionName.new(name).has_type?(value)
    [value, name.remove_type(value).fingerprint]
  end * ":"
end

census_subdivision_with_type_map = lambda do |(value,name)|
  value = CensusSubdivisionName.identifier_from_name(name) || value
  name = CensusSubdivisionName.new(name).normalize
  if value[/\Aocd-division/]
    identifier = CensusSubdivisionIdentifier.new(value)
    [identifier.province_or_territory_type_id, identifier.census_subdivision_type, name.fingerprint]
  else
    return nil if CensusDivisionName.new(name).has_type?(value)
    [value, name.type(value).to_s, name.remove_type(value).fingerprint]
  end * ":"
end

census_subdivisions = OpenCivicDataIdentifiers.read("country-ca/ca_census_subdivisions")
census_subdivisions_hash = Lycopodium.new(census_subdivisions, census_subdivision_map).reject_collisions.value_to_fingerprint.invert
census_subdivisions_with_types_hash = Lycopodium.new(census_subdivisions, census_subdivision_with_type_map).reject_collisions.value_to_fingerprint.invert

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

# Use in case the FCM URL cannot be reached.
URL_UNREACHABLE = {
  # NL
  1001469 => 'http://townofhmcclv.com',
  1001519 => 'http://www.stjohns.ca',
  1008059 => 'http://southbrook.tripod.com',
  # PE
  1102085 => 'http://cornwallpe.ca',
  1103042 => 'http://www.communityofoleary.com',
  # NS
  1202006 => 'http://townofyarmouth.ca',
  1212008 => 'http://www.westville.ca',
  1212016 => 'http://www.town.trenton.ns.ca',
  1213008 => 'http://www.townofmulgrave.ca',
  # NB
  1304022 => 'http://www.villageofminto.ca',
  1306020 => 'http://www.townofriverview.ca',
  1310037 => 'http://www.thevillageofstanley.ca',
  1313002 => 'http://www.saintandrenb.ca',
  1314017 => 'http://www.dalhousie.ca',
  1315013 => 'http://www.pointe-verte.ca',
  1315015 => 'http://beresford.ca',
  1315017 => 'http://www.saint-louis-de-kent.ca',
  1315031 => 'http://www.shippagan.ca',
  # QC
  2405020 => 'http://www.municipalitehopetown.ca',
  2413073 => 'http://temiscouatasurlelac.ca',
  2414018 => 'http://www.villesaintpascal.com',
  2434090 => 'http://www.saintubalde.com',
  2446035 => 'http://www.ville.bedford.qc.ca',
  2451045 => 'http://www.saint-justin.ca',
  2457040 => 'http://ville.beloeil.qc.ca',
  2475017 => 'http://www.ville.saint-jerome.qc.ca',
  2482025 => 'http://www.chelsea.ca',
  2483032 => 'http://www.gracefield.ca',
  2483055 => 'http://www.sainte-therese-de-la-gatineau.ca',
  2485050 => 'http://laverlochere.net',
  2485060 => 'http://www.latulipeetgaboury.net',
  2487120 => 'http://st-lambert.ao.ca',
  # ON
  3502008 => 'http://www.hawkesbury.ca',
  3502025 => 'http://www.nationmun.ca',
  3512048 => 'http://www.tudorandcashel.com',
  3518009 => 'http://www.whitby.ca',
  3518039 => 'http://townshipofbrock.ca',
  3523008 => 'http://guelph.ca',
  3523033 => 'http://www.mapleton.ca',
  3524002 => 'http://cms.burlington.ca',
  3539060 => 'http://www.lucanbiddulph.on.ca',
  3540005 => 'http://www.southhuron.ca',
  3543042 => 'http://www.barrie.ca',
  3547090 => 'http://www.laurentianhills.ca',
  3547096 => 'http://www.deepriver.ca',
  3559001 => 'http://www.atikokan.ca',
  3560008 => 'http://www.snnf.ca',
  # MB
  4603040 => 'https://altona.ca',
  4603047 => 'http://www.rmofstanley.ca',
  4603067 => 'http://townofmorris.ca',
  4605067 => 'http://www.whitewaterrm.ca',
  4608061 => 'http://www.gladstone.ca',
  4609020 => 'http://www.stclaude.ca',
  4614042 => 'http://www.teulon.ca',
  4620048 => 'http://www.swanrivermanitoba.ca',
  # SK
  4701049 => 'http://redvers.ca',
  4707031 => 'http://www.chaplin.ca',
  4707039 => 'http://www.moosejaw.ca',
  4708012 => 'http://www.villageoftompkins.ca',
  4708024 => 'http://rm171fv.com',
  4714051 => 'http://www.cityofmelfort.ca',
  4718070 => 'http://buffalonarrows.net',
  # AB
  4802022 => 'http://www.taber.ca',
  4802036 => 'http://www.villageofduchess.com',
  4803004 => 'http://cardston.ca',
  4804014 => 'http://www.townofoyen.com',
  4804022 => 'http://www.consort.ca',
  4805048 => 'http://www.threehills.ca',
  4807054 => 'http://www.wainwright.ca',
  4808008 => 'http://www.innisfail.ca',
  4808012 => 'http://www.sylvanlake.ca',
  4810028 => 'http://www.vegreville.com',
  4810044 => 'http://www.marwayne.ca',
  4811009 => 'http://www.silverbeach.ca',
  4811066 => 'http://www.bonaccord.ca',
  4812020 => 'http://www.svhorseshoebay.com',
  4813007 => 'http://summervillageofyellowstone.com',
  4817078 => 'http://www.manning.govoffice.com',
  4819011 => 'http://www.wembley.ca',
  # BC
  5915802 => 'http://www.tsawwassenfirstnation.com',
}

failures = []
unmatched = []

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

class Redirection < StandardError; end

Nokogiri::HTML(open("http://www.fcm.ca/home/about-us/membership/our-members.htm")).css("tbody tr").each do |tr|
  fingerprint = province_or_territory_map.call([nil, tr.at_css("td:eq(2)").text])
  province_or_territory = provinces_and_territories_hash.fetch(fingerprint).first[/[^:]+\z/]

  Nokogiri::HTML(open(tr.at_css("a")[:href])).css("ul.membership li").each do |li|
    a = li.at_css("a")
    next unless a && a[:href]["@"].nil?

    value = li.text.strip
    next if MUNICIPAL_ASSOCIATIONS.include?(value)

    fingerprint = census_subdivision_map.call([province_or_territory, value])
    census_subdivision = census_subdivisions_hash[fingerprint]

    unless census_subdivision
      fingerprint = census_subdivision_with_type_map.call([province_or_territory, value])
      census_subdivision = census_subdivisions_with_types_hash[fingerprint]
    end
    if census_subdivision
      type_id = census_subdivision.first[/[^:]+\z/].to_i
      if URL_OVERRIDE.key?(type_id)
        url = URL_OVERRIDE[type_id]
      else
        url = clean_url(a[:href].sub(%r{\A(http://)(?:http:/)?/}, '\1'))
        url_parse = URI.parse(url)

        begin
          response = Faraday.get(url) do |request|
            request.headers["User-Agent"] = "Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; WOW64; Trident/6.0)" # IE 10
          end

          if [301, 302, 303].include?(response.status)
            redirect_url = clean_url(response.headers["location"], url)
            redirect_url_parse = URI.parse(redirect_url)

            # If it redirects to a URL without a path, redirect from a URL with
            # a path, or redirects to a path on a new domain, use the new URL.
            # If it redirects from a URL without a path to a URL with a path on
            # the same domain, use the old URL.
            if redirect_url_parse.path.empty? || !url_parse.path.empty? || url_parse.host != redirect_url_parse.host
              url = redirect_url
              url_parse = URI.parse(url)
              raise Redirection
            end
          elsif response.status == 200 && !url_parse.path.empty?
            new_url_parse = url_parse.dup
            new_url_parse.path = ""
            # If the path is a root index page, remove the path.
            if url_parse.path[%r{\A/(?:en/|fr/)?(?:index.(?:aspx?|cfm|html?|jsp|php))?\z}]
              url = new_url_parse.to_s
            # If the TLD redirects to the URL, use the TLD.
            else
              response = Faraday.get(new_url_parse.to_s)
              if response.status == 200
                meta = Nokogiri::HTML(response.body).at_css('meta[http-equiv="REFRESH"],meta[http-equiv="refresh"]')
                if meta && meta['content'][/url=(.+)/i, 1] == url
                  url = new_url_parse.to_s
                end
              elsif [301, 302].include?(response.status) && [url, url_parse.path].include?(response.headers["location"])
                url = new_url_parse.to_s
              end
            end
          elsif response.status != 200
            if URL_UNREACHABLE.key?(type_id)
              url = URL_UNREACHABLE[type_id]
            else
              failures << [type_id, census_subdivision.last, url, response.status]
              next
            end
          end
        rescue Redirection
          # Can't retry outside of rescue.
          retry
        rescue Faraday::Error::ConnectionFailed, Faraday::Error::TimeoutError, Errno::ETIMEDOUT => e
          if URL_UNREACHABLE.key?(type_id)
            url = URL_UNREACHABLE[type_id]
          else
            failures << [type_id, census_subdivision.last, url, "#{e.class.name} #{e.message}"]
            next
          end
        end
      end

      output("csd:", type_id, url)
    else
      unmatched << "#{value.ljust(60)} #{fingerprint}" if fingerprint
    end
  end
end

$stderr.puts "Unmatched:"
$stderr.puts unmatched
$stderr.puts
$stderr.puts "Failures:"
failures.each do |type_id,name,url,message|
  $stderr.puts "#{type_id} #{name.ljust(20)} #{url.ljust(60)} #{message}"
end
