#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

require "lycopodium"
require "nokogiri"
require "unicode_utils/upcase"

class OpenCivicDataFile < Array
  class << self
    attr_reader :directory

    def read(path)
      new(CSV.read(File.expand_path(File.join("..", "..", "..", directory, path + ".csv"), __FILE__)))
    end
  end

  def abbreviate!
    replace(map{|identifier,value| [identifier[/[^:]+\z/], value]})
  end

  def to_h
    Hash[*flatten]
  end
end

class OpenCivicDataIdentifiers < OpenCivicDataFile
  @directory = "identifiers"
end

class OpenCivicDataMappings < OpenCivicDataFile
  @directory = "mappings"
end

class DivisionName < String
  class << self
    attr_reader :divisions, :identifier_mappings, :name_mappings, :type_mappings, :type_patterns

    def identifier_from_name(name)
      identifier_mappings[name]
    end
  end

  def remove_type(province_or_territory)
    sub(pattern(province_or_territory), "")
  end

  def has_type?(province_or_territory)
    !!self[pattern(province_or_territory)]
  end

  def type(province_or_territory)
    matches = match(pattern(province_or_territory))
    mapping = type_mappings.fetch(province_or_territory)
    mapping.fetch(matches.captures.compact.first) if matches
  end

private

  def pattern(province_or_territory)
    type_patterns.fetch(province_or_territory)
  end

  def alternate_or_self
    if identifier_mappings.key?(self)
      self.class.new(divisions.fetch(identifier_mappings[self]))
    elsif name_mappings.key?(self)
      self.class.new(name_mappings[self])
    else
      self
    end
  end

  def divisions
    self.class.divisions
  end

  def identifier_mappings
    self.class.identifier_mappings
  end

  def name_mappings
    self.class.name_mappings
  end

  def type_mappings
    self.class.type_mappings
  end

  def type_patterns
    self.class.type_patterns
  end
end

class CensusDivisionName < DivisionName
  # @see http://www12.statcan.gc.ca/census-recensement/2011/ref/dict/table-tableau/table-tableau-4-eng.cfm
  @type_mappings = {
    "ab" => {},
    "bc" => {
      "Regional District" => "RD",
    },
    "mb" => {},
    "nb" => {},
    "nl" => {},
    "ns" => {
      "County" => "CTY",
      "Region" => "CTY",
      "Municipality of the County" => "CTY",
    },
    "nt" => {},
    "nu" => {},
    "on" => {
      "County" => "CTY",
      "Region" => "RM",
      "Regional Municipality" => "RM",
      "United Counties" => "UC",
    },
    "pe" => {},
    "qc" => {
      "Communauté métropolitaine" => "Territoire équivalent",
      "MRC" => "MRC",
    },
    "sk" => {},
    "yt" => {},
  }

  @type_patterns = @type_mappings.each_with_object({}) do |(identifier,value),patterns|
    pattern = value.keys * "|"
    patterns[identifier] = /\A(#{pattern}) (?:d'|de |des |of )?| (#{pattern})\z/
  end
end

class CensusSubdivisionName < DivisionName
  @divisions = OpenCivicDataIdentifiers.read("country-ca/ca_census_subdivisions").to_h

  @identifier_mappings = {
    # http://en.wikipedia.org/wiki/Redwood_Meadows,_Alberta
    "Townsite of Redwood Meadows" => "ocd-division/country:ca/csd:4806804",
    # http://woodypoint.ca/
    "Town of Woody Point"         => "ocd-division/country:ca/csd:1009011",
    # http://www.gov.pe.ca/placefinder/index.php3?city=North%20Shore
    "Community of North Shore"    => "ocd-division/country:ca/csd:1102052",
    # http://www.gov.pe.ca/placefinder/index.php3?city=St.%20Nicholas
    "Community of St. Nicholas"   => "ocd-division/country:ca/csd:1103019",
  }

  @name_mappings = {
    # StatCan has alternate names for the following:
    "Clear Hills County" => "Clear Hills", # AB
    "County of Newell"   => "Newell County No. 4", # AB
    # The following errors have been reported to FCM:
    "County of Vermilion River No. 24"             => "County of Vermilion River", # AB
    "Rural Municipality of Archie No. 101"         => "Rural Municipality of Archie", # MB
    "Rural Municipality of Ellice No 123"          => "Rural Municipality of Ellice", # MB
    "Town of Lushes Bight-Beaumont-Beaumont Morth" => "Town of Lushes Bight-Beaumont-Beaumont North", # NL
    "United Townships of Head, Clara, Marian"      => "United Townships of Head, Clara, Maria", # ON
    "Cantons unis de Latulippe-et-Gaboury"         => "Cantons unis de Latulipe-et-Gaboury", # QC
  }

  # @see http://www12.statcan.gc.ca/census-recensement/2011/ref/dict/table-tableau/table-tableau-5-eng.cfm
  @type_mappings = {
    # Unused: "ID", "IRI", "S-É", "SA".
    "ab" => {
      "City"                           => "CY",
      "County"                         => "MD",
      "Municipal District"             => "MD",
      "Municipality"                   => "SM",
      "Regional Municipality"          => "SM",
      "Summer Village"                 => "SV",
      "Town"                           => "T",
      "Village"                        => "VL",
    },
    # Unused: "NL", "RDA", "S-É".
    "bc" => {
      "City"                           => "CY",
      "Corporation of the Village"     => "VL",
      "Corporation"                    => "DM",
      "District"                       => "DM",
      "First Nation"                   => "IRI",
      "Indian Government District"     => "IGD",
      "Municipality"                   => "IM",
      "Regional Municipality"          => "RGM",
      "Resort Municipality"            => "DM",
      "Town"                           => "T",
      "Township"                       => "DM",
      "Village"                        => "VL",
    },
    # Unused: "IRI", "NO", "S-É".
    "mb" => {
      "City"                           => "CY",
      "Local Government District"      => "LGD",
      "Municipality"                   => "RM",
      "Rural Municipality"             => "RM",
      "Town"                           => "T",
      "Village"                        => "VL",
    },
    # Unused: "IRI", "P". Overlap: "C", "TV".
    "nb" => {
      "City"                           => "CY",
      "Communauté rurale"              => "RCR",
      "Rural Community"                => "RCR",
      "Town"                           => "T",
      "Village"                        => "VL",
      "Ville"                          => "T",
    },
    # Unused: "IRI", "RG", "SNO".
    "nl" => {
      "City"                           => "CY",
      "Community Government"           => "T",
      "Community"                      => "T",
      "Municipality"                   => "T",
      "Town"                           => "T",
    },
    # Unused: "IRI", "SC".
    "ns" => {
      "District"                       => "MD",
      "Municipality of the District"   => "MD",
      "Municipality"                   => "MD",
      "Regional Municipality"          => "RGM",
      "Town"                           => "T",
    },
    # Unused: "IRI", "NO", "SET".
    "nt" => {
      "Chartered Community"            => "CC",
      "City"                           => "CY",
      "Community Government"           => "CG",
      "Hamlet"                         => "HAM",
      "Town"                           => "T",
      "Village"                        => "VL",
    },
    # Unused: "NO", "SET".
    "nu" => {
      "City"                           => "CY",
      "Hamlet"                         => "HAM",
      "Municipality"                   => "HAM",
    },
    # Unused: "IRI", "NO", "S-É". Overlap: "C", "CV", "M", "TV".
    "on" => {
      "Canton"                         => "TP",
      "Cité"                           => "CY",
      "City"                           => "CY",
      "Municipalité"                   => "TP",
      "Municipality"                   => "MU",
      "Town"                           => "T",
      "Township"                       => "TP",
      "United Townships"               => "TP",
      "Village"                        => "VL",
      "Ville"                          => "T",
    },
    # Unused: "IRI", "LOT".
    "pe" => {
      "City"                           => "CY",
      "Community"                      => "COM",
      "Town"                           => "T",
    },
    # Unused: "IRI", "NO", "S-É", "TC", "TI", "TK", "VC", "VK".
    "qc" => {
      "Canton"                         => "CT",
      "Cantons unis"                   => "CU",
      "Cantons Unis"                   => "CU",
      "Cité"                           => "V",
      "City"                           => "V",
      "Muncipalité"                    => "MÉ",
      "Municipalité du Canton"         => "CT",
      "Municipalité"                   => "MÉ",
      "Municipality"                   => "MÉ",
      "Northern Village"               => "VN",
      "Paroisse"                       => "PE",
      "Town"                           => "V",
      "Village Nordique"               => "VN",
      "Village"                        => "VL",
      "Ville"                          => "V",
    },
    # Unused: "CN", "IRI", "NO", "S-É".
    "sk" => {
      "City"                           => "CY",
      "Northern Hamlet"                => "NH",
      "Northern Village"               => "NV",
      "Resort Village of the District" => "RV",
      "Resort Village"                 => "RV",
      "Rural Municipality"             => "RM",
      "Town"                           => "T",
      "Village"                        => "VL",
    },
    # Unused: "HAM", "NO", "S-É", "SG", "SÉ", "TL".
    "yt" => {
      "City"                           => "CY",
      "Town"                           => "T",
      "Village"                        => "VL",
    },
  }

  @type_patterns = @type_mappings.each_with_object({}) do |(identifier,value),patterns|
    pattern = value.keys * "|" # Don't remove "County" from end of string.
    patterns[identifier] = /\A(#{pattern}) (?:d'|de |des |of )?| (#{pattern.sub("|County|", "|")})\z/
  end

  def normalize
    alternate_or_self.
    squeeze(" ").                                          # Remove extra spaces, e.g. "Municipalité de  Baie-James"
    sub(/(?<=No\.)(?=\S)/, " ").                           # Add a space after "No.", e.g. "Rural Municipality of Maple Creek No.111"
    sub(/(?<=No\. )0/, "").                                # Remove leading zero, e.g. "Rural Municipality of Coalfields No. 04"
    sub(/\ACounty of (.+?)( No\. \d+)?\z/, '\1 County\2'). # Re-order words, e.g. "County of Barrhead No. 11"
    sub(/ \((?:AB|MB|NB|NL|ON)\)\z/, "").                  # Remove province, e.g. "Cochrane (AB)"
    sub(/ 100 /, " One Hundred ").                         # Replace infix number, e.g. "District of 100 Mile House"
    gsub(/[ -](?:and|de|et)[ -]/, " ").                    # Remove linking words
    sub(/\bSt(e)?\b\.?/, 'Saint\1')                        # Expand "St." and "Ste."
  end

  def fingerprint
    tr(
      "ÀÁÂÃÄÅàáâãäåĀāĂăĄąÇçĆćĈĉĊċČčÐðĎďĐđÈÉÊËèéêëĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħÌÍÎÏìíîïĨĩĪīĬĭĮįİıĴĵĶķĸĹĺĻļĽľĿŀŁłÑñŃńŅņŇňŉŊŋÒÓÔÕÖØòóôõöøŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞşŠšſŢţŤťŦŧÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲųŴŵÝýÿŶŷŸŹźŻżŽž",
      "aaaaaaaaaaaaaaaaaaccccccccccddddddeeeeeeeeeeeeeeeeeegggggggghhhhiiiiiiiiiiiiiiiiiijjkkkllllllllllnnnnnnnnnnnoooooooooooooooooorrrrrrsssssssssttttttuuuuuuuuuuuuuuuuuuuuwwyyyyyyzzzzzz"
    ).                                                  # Remove accents
    upcase.                                             # Normalize case
    split(%r{[ &,/-]}).reject(&:empty?).sort.join("~"). # Re-order words, N.B.: "Ville-Marie" and "Marieville"
    gsub(/\p{Punct}|\p{Space}/, "")                     # Remove punctuation and spaces
  end

  def type(province_or_territory)
    super || begin
      mapping = type_mappings.fetch(province_or_territory)
      mapping[mapping.keys.include?("County") && self[/ (County)\z/, 1]]
    end
  end
end

class CensusSubdivisionIdentifier < String
  @census_subdivision_types = OpenCivicDataMappings.read("country-ca-types/ca_census_subdivisions").to_h
  @province_and_territory_sgc_codes = OpenCivicDataMappings.read("country-ca-sgc/ca_provinces_and_territories").abbreviate!.to_h.invert

  class << self
    attr_reader :census_subdivision_types, :province_and_territory_sgc_codes
  end

  def province_or_territory_type_id
    self.class.province_and_territory_sgc_codes.fetch(province_or_territory_sgc_code)
  end

  def province_or_territory_sgc_code
    self[/[^:]+\z/][0,2]
  end

  def census_division_type_id
    self[/[^:]+\z/][0,4]
  end

  def census_subdivision_type
    self.class.census_subdivision_types.fetch(self).sub(/\ATV\z/, "T").sub(/\AC\z/, "CY")
  end
end



province_or_territory_map = lambda do |(_,name)|
  # Effective October 20, 2008, the name "Yukon Territory" became "Yukon". The
  # name "Nunavut" was never "Nunavut Territory". The English name is "Quebec".
  # @see http://www.statcan.gc.ca/subjects-sujets/standard-norme/sgc-cgt/notice-avis/sgc-cgt-01-eng.htm
  name.sub(" Territory", "").tr("é", "e")
end

provinces_and_territories = OpenCivicDataIdentifiers.read("country-ca/ca_provinces_and_territories")
provinces_and_territories_hash = Lycopodium.new(provinces_and_territories, province_or_territory_map).hash_to_value

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
census_subdivisions_hash = Lycopodium.new(census_subdivisions, census_subdivision_map).reject_collisions.hash_to_value
census_subdivisions_with_types_hash = Lycopodium.new(census_subdivisions, census_subdivision_with_type_map).reject_collisions.hash_to_value

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

warnings = []

Nokogiri::HTML(open("http://www.fcm.ca/home/about-us/membership/our-members.htm")).css("tr:gt(1)").each do |tr|
  fingerprint = province_or_territory_map.call([nil, tr.at_css("td:eq(2)").text])
  province_or_territory = provinces_and_territories_hash.fetch(fingerprint).first[/[^:]+\z/]

  Nokogiri::HTML(open(tr.at_css("a")[:href])).css("ul.membership li").each do |li|
    a = li.at_css("a")
    next unless a

    value = li.text.strip
    next if MUNICIPAL_ASSOCIATIONS.include?(value)

    fingerprint = census_subdivision_map.call([province_or_territory, value])
    census_subdivision = census_subdivisions_hash[fingerprint]

    unless census_subdivision
      fingerprint = census_subdivision_with_type_map.call([province_or_territory, value])
      census_subdivision = census_subdivisions_with_types_hash[fingerprint]
    end
    if census_subdivision
      output("csd:",
        census_subdivision.first[/[^:]+\z/],
        a[:href].sub("http://http://", "http://"))
    else
      warnings << "#{value.ljust(70)} #{fingerprint}" if fingerprint
    end
  end
end

$stderr.puts "Unmatched:"
$stderr.puts warnings
