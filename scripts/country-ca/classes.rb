# coding: utf-8

require "lycopodium"

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
    # @note Use if scraped names may be significantly different from official names.
    def identifier_from_name(name)
      identifier_mappings[name]
    end
  end

  # Removes the census subdivision type from the division name.
  #
  # @example
  #   CensusDivisionName.new("County of York").remove_type("on") # "York"
  #   CensusSubdivisionName.new("City of Toronto").remove_type("on") # "Toronto"
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

  # @note This method would previously reorder words; however, word order
  # disambiguates "Saint-Esprit" and "Esprit-Saint". Separators were kept to
  # disambiguate "Ville-Marie" and "Marieville".
  def fingerprint
    tr(
      "ÀÁÂÃÄÅàáâãäåĀāĂăĄąÇçĆćĈĉĊċČčÐðĎďĐđÈÉÊËèéêëĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħÌÍÎÏìíîïĨĩĪīĬĭĮįİıĴĵĶķĸĹĺĻļĽľĿŀŁłÑñŃńŅņŇňŉŊŋÒÓÔÕÖØòóôõöøŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞşŠšſŢţŤťŦŧÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲųŴŵÝýÿŶŷŸŹźŻżŽž",
      "aaaaaaaaaaaaaaaaaaccccccccccddddddeeeeeeeeeeeeeeeeeegggggggghhhhiiiiiiiiiiiiiiiiiijjkkkllllllllllnnnnnnnnnnnoooooooooooooooooorrrrrrsssssssssttttttuuuuuuuuuuuuuuuuuuuuwwyyyyyyzzzzzz"
    ).                                             # Remove accents
    upcase.                                        # Normalize case
    split(%r{[ &,/-]}).reject(&:empty?).join("~"). # Normalize separators
    gsub(/\p{Punct}|\p{Space}/, "")                # Remove punctuation and spaces
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
  @identifier_mappings = {}

  @name_mappings = {}

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

  @type_patterns = {}.tap do |patterns|
    @type_mappings.each do |province_or_territory_type_id,hash|
      pattern = hash.keys * "|"
      patterns[province_or_territory_type_id] = /\A(#{pattern}) (?:d'|de |des |of )?| (#{pattern})\z/
    end
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
    "Region of Queens Municipality" => "Queens", # NS
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

  @type_patterns = {}.tap do |patterns|
    @type_mappings.each do |province_or_territory_type_id,hash|
      pattern = hash.keys * "|" # Don't remove "County" from end of string.
      patterns[province_or_territory_type_id] = /\A(#{pattern}) (?:d'|de |des |of )?| (#{pattern.sub("|County|", "|")})\z/
    end
  end

  def type(province_or_territory)
    super || begin
      mapping = type_mappings.fetch(province_or_territory)
      mapping[mapping.keys.include?("County") && self[/ (County)\z/, 1]]
    end
  end
end

class CensusDivisionIdentifier < String
  @census_division_types = OpenCivicDataMappings.read("country-ca-types/ca_census_divisions").to_h
  @province_and_territory_sgc_codes = OpenCivicDataMappings.read("country-ca-sgc/ca_provinces_and_territories").abbreviate!.to_h.invert

  class << self
    attr_reader :census_division_types, :province_and_territory_sgc_codes
  end

  # Returns the province or territory's type ID (also its postal abbreviation).
  def province_or_territory_type_id
    self.class.province_and_territory_sgc_codes.fetch(province_or_territory_sgc_code)
  end

  # Returns the province or territory SGC code, e.g. "24", which is the first
  # two digits of the census division SGC code.
  def province_or_territory_sgc_code
    self[/[^:]+\z/][0,2]
  end

  # Returns the census division type ID (also its SGC code).
  def census_division_type_id
    self[/[^:]+\z/][0,4]
  end

  # Returns the census division's type.
  def census_division_type
    self.class.census_division_types.fetch("ocd-division/country:ca/csd:#{census_division_type_id}")
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

  # Returns the census subdivision type ID (also its SGC code).
  def census_subdivision_type_id
    self[/[^:]+\z/][0,7]
  end

  # Returns the census subdivision's type.
  def census_subdivision_type
    self.class.census_subdivision_types.fetch("ocd-division/country:ca/csd:#{census_subdivision_type_id}").sub(/\ATV\z/, "T").sub(/\AC\z/, "CY")
  end
end

class CensusDivisionNameMatcher
  # census_division_map.call(["on", "York"]) # "on:YORK"
  @census_division_map = lambda do |(value,name)|
    value = CensusDivisionName.identifier_from_name(name) || value
    name = CensusDivisionName.new(name).normalize
    if value[/\Aocd-division/] # `value` is an OCD identifier
      [CensusDivisionIdentifier.new(value).province_or_territory_type_id, name.fingerprint]
    else # `value` is a province of territory type ID
      [value, name.remove_type(value).fingerprint]
    end * ":"
  end

  @census_divisions = OpenCivicDataIdentifiers.read("country-ca/ca_census_divisions")
  @census_divisions_hash = Lycopodium.new(@census_divisions, @census_division_map).reject_collisions.value_to_fingerprint.invert

  def self.fingerprint(province_or_territory_type_id, name)
    @census_division_map.call([province_or_territory_type_id, name])
  end

  def self.identifier_and_name(fingerprint)
    @census_divisions_hash[fingerprint]
  end
end

class CensusSubdivisionNameMatcher
  # census_subdivision_map.call(["on", "Toronto"]) # "on:TORONTO"
  @census_subdivision_map = lambda do |(value,name)|
    value = CensusSubdivisionName.identifier_from_name(name) || value
    name = CensusSubdivisionName.new(name).normalize
    if value[/\Aocd-division/] # `value` is an OCD identifier
      identifier = CensusSubdivisionIdentifier.new(value)
      [identifier.province_or_territory_type_id, name.fingerprint]
    else # `value` is a province of territory type ID
      return nil if CensusDivisionName.new(name).has_type?(value) # skip census divisions
      [value, name.remove_type(value).fingerprint]
    end * ":"
  end

  @census_subdivisions = OpenCivicDataIdentifiers.read("country-ca/ca_census_subdivisions")
  @census_subdivisions_hash = Lycopodium.new(@census_subdivisions, @census_subdivision_map).reject_collisions.value_to_fingerprint.invert

  def self.fingerprint(province_or_territory_type_id, name)
    @census_subdivision_map.call([province_or_territory_type_id, name])
  end

  def self.identifier_and_name(fingerprint)
    @census_subdivisions_hash[fingerprint]
  end
end

class CensusSubdivisionNameTypeMatcher
  # census_subdivision_with_type_map.call(["on", "City of Toronto"]) # "on:CY:TORONTO"
  @census_subdivision_with_type_map = lambda do |(value,name)|
    value = CensusSubdivisionName.identifier_from_name(name) || value
    name = CensusSubdivisionName.new(name).normalize
    if value[/\Aocd-division/] # `value` is an OCD identifier
      identifier = CensusSubdivisionIdentifier.new(value)
      [identifier.province_or_territory_type_id, identifier.census_subdivision_type, name.fingerprint]
    else # `value` is a province of territory type ID
      return nil if CensusDivisionName.new(name).has_type?(value) # skip census divisions
      [value, name.type(value).to_s, name.remove_type(value).fingerprint]
    end * ":"
  end

  @census_subdivisions = OpenCivicDataIdentifiers.read("country-ca/ca_census_subdivisions")
  @census_subdivisions_with_types_hash = Lycopodium.new(@census_subdivisions, @census_subdivision_with_type_map).reject_collisions.value_to_fingerprint.invert

  def self.fingerprint(province_or_territory_type_id, name_with_type)
    @census_subdivision_with_type_map.call([province_or_territory_type_id, name_with_type])
  end

  def self.identifier_and_name(fingerprint)
    @census_subdivisions_with_types_hash[fingerprint]
  end
end
