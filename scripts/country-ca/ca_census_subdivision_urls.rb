#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)

require "faraday"
require "lycopodium"
require "nokogiri"
require "unicode_utils/upcase"

class OpenCivicDataFile < Array
  class << self
    attr_reader :directory

    # Reads a local CSV file.
    def read(path)
      new(CSV.read(File.expand_path(File.join("..", "..", "..", directory, path + ".csv"), __FILE__)))
    end
  end

  # Transforms the OCD identifiers to type IDs.
  def abbreviate!
    replace(map{|identifier,value| [identifier[/[^:]+\z/], value]})
  end

  # Transforms the two-column CSV to a hash.
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

    # Returns the OCD identifier for the name.
    def identifier_from_name(name)
      identifier_mappings[name]
    end
  end

  # Removes the census subdivision type from the division name.
  def remove_type(province_or_territory)
    sub(pattern(province_or_territory), "")
  end

  # Returns whether the division name contains a census subdivision type.
  def has_type?(province_or_territory)
    !!self[pattern(province_or_territory)]
  end

  # Returns the census subdivision type code.
  def type(province_or_territory)
    matches = match(pattern(province_or_territory))
    mapping = type_mappings.fetch(province_or_territory)
    mapping.fetch(matches.captures.compact.first) if matches
  end

private

  # Returns the regular expression for capturing a census subdivision type in a
  # particular province or territory.
  def pattern(province_or_territory)
    type_patterns.fetch(province_or_territory)
  end

  # Returns the scraped name, an alternate name, or the official name.
  def alternate_or_self
    if identifier_mappings.key?(self)
      self.class.new(divisions.fetch(identifier_mappings[self]))
    elsif name_mappings.key?(self)
      self.class.new(name_mappings[self])
    else
      self
    end
  end

  # Returns a hash from OCD identifier to official name.
  def divisions
    self.class.divisions
  end

  # Returns a hash from a scraped name to an OCD identifier. Used in cases where
  # the scraped name has no resemblance to the official name.
  def identifier_mappings
    self.class.identifier_mappings
  end

  # Returns a hash from a scraped name to an alternate name. Used in cases where
  # the scraped name has a typo or major differences from the official name.
  def name_mappings
    self.class.name_mappings
  end

  # Returns a hash in which the keys are province or territory type IDs and the
  # values are hashes in which the keys are census subdivision type names and
  # the values are census subdivision type codes.
  def type_mappings
    self.class.type_mappings
  end

  # Returns a hash in which the keys are province or territory type IDs and the
  # values are regular expressions for capturing a census subdivision type.
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
    "Townsite of Redwood Meadows" => "ocd-division/country:ca/csd:4806804", # Tsuu T'ina Nation 145 (Sarcee 145)
    # http://woodypoint.ca/
    "Town of Woody Point"         => "ocd-division/country:ca/csd:1009011", # Woody Point, Bonne Bay
    # http://www.gov.pe.ca/placefinder/index.php3?city=North%20Shore
    "Community of North Shore"    => "ocd-division/country:ca/csd:1102052", # Lot 34
    # http://www.gov.pe.ca/placefinder/index.php3?city=St.%20Nicholas
    "Community of St. Nicholas"   => "ocd-division/country:ca/csd:1103019", # Lot 17
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

  # Returns the province or territory's type ID (also its postal abbreviation).
  def province_or_territory_type_id
    self.class.province_and_territory_sgc_codes.fetch(province_or_territory_sgc_code)
  end

  # Returns the province or territory SGC code, e.g. "24", which is the first
  # two digits of the census subdivision SGC code.
  def province_or_territory_sgc_code
    self[/[^:]+\z/][0,2]
  end

  # Returns the census division type ID (also its SGC code), which is the first
  # four digits of the census subdivision SGC code.
  def census_division_type_id
    self[/[^:]+\z/][0,4]
  end

  # Returns the census subdivision's type.
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
