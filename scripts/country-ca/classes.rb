# coding: utf-8

require "lycopodium"

class OpenCivicDataIdentifiers < Array
  class << self
    # Reads a local CSV file.
    def read(path)
      rows = CSV.read(File.expand_path(File.join("..", "..", "..", "identifiers", path + ".csv"), __FILE__))
      rows.shift
      new(rows)
    end
  end

  # Transforms the OCD identifiers to type IDs.
  def abbreviate!
    replace(map{|identifier,*args| [identifier[/[^:]+\z/], *args]})
  end

  def mapping(index = 0)
    map{|identifier,*args| [identifier, args[index]]}
  end

  # Transforms the two-column CSV to a hash.
  def to_h(index = 0)
    Hash[*mapping(index).flatten]
  end
end

class DivisionName < String
  class << self
    attr_reader :name_mappings, :type_patterns
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

  def normalize
    alternate_or_self.
    squeeze(" ").                                          # Remove extra spaces
    sub(/(?<=No\.)(?=\S)/, " ").                           # Add a space after "No.", e.g. "RM of ARGYLE No.1"
    sub(/\b100 /, "One Hundred ").                         # Replace prefix or infix number, e.g. "100 Mile House"
    sub(/\bSt(e)?\b\.?/i, 'Saint\1')                       # Expand "St." and "Ste."
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
    type_patterns[province_or_territory] || /(?=a)b/
  end

  # Returns the scraped name, an alternate name, or the official name.
  def alternate_or_self
    if name_mappings.key?(self)
      self.class.new(name_mappings[self])
    else
      self
    end
  end

  # Returns a hash from a scraped name to an alternate name. Used in cases where
  # the scraped name has a typo or major differences from the official name.
  def name_mappings
    self.class.name_mappings
  end

  # Returns a hash in which the keys are province or territory type IDs and the
  # values are regular expressions for capturing a census subdivision type.
  def type_patterns
    self.class.type_patterns
  end
end

class CensusDivisionName < DivisionName
  @name_mappings = {}

  @type_patterns = {}.tap do |patterns|
    # @see http://www12.statcan.gc.ca/census-recensement/2016/ref/dict/tab/t1_4-eng.cfm
    {
      "ns" => {
        "County" => "CTY",
      },
    }.each do |province_or_territory_type_id,hash|
      pattern = hash.keys * "|"
      patterns[province_or_territory_type_id] = /\A(#{pattern}) (?:d'|de |des |of )?| (#{pattern})\z/
    end
  end
end

class CensusSubdivisionName < DivisionName
  @name_mappings = {
    # http://www.election2014.civicinfo.bc.ca/2014/reports/report_adv_results.asp?excel=yes&etype=%27MAYOR%27,%20%27COUNCILLOR%27
    "Sun Peaks" => "Sun Peaks Mountain",
    # http://geonb.snb.ca/ArcGIS/rest/services/GeoNB_ENB_MunicipalWards/MapServer/0?f=json
    "Beaubassin East\\Beaubassin-Est" => "Beaubassin East",
    "Campobello" => "Campobello Island",
    "Edmunston" => "Edmundston",
    "Grand Falls\\Grand-Sault" => "Grand Falls",
    # http://www.novascotia.ca/dma/pdf/mun-municipal-election-results-2008-2012.xls
    "Region of Queens Municipality" => "Queens",
    # http://www.mah.gov.on.ca/Page1591.aspx
    "Dysart, Dudley, Harcourt, Guilford, Harburn, Bruton, Havelock, Eyre and Clyde" => "Dysart et al",
  }

  @type_patterns = {}.tap do |patterns|
    # @see http://www12.statcan.gc.ca/census-recensement/2016/ref/dict/tab/t1_5-eng.cfm
    {
      # http://www.novascotia.ca/dma/pdf/mun-municipal-election-results-2008-2012.xls
      "ns" => {
        "Regional Municipality" => "RGM",
        "Town" => "T",
      },
    }.each do |province_or_territory_type_id,hash|
      pattern = hash.keys * "|" # Don't remove "County" from end of string.
      patterns[province_or_territory_type_id] = /\A(#{pattern}) (?:d'|de |des |of )?| (#{pattern.sub("|County|", "|")})\z/
    end
  end
end

class CensusDivisionIdentifier < String
  @census_division_types = OpenCivicDataIdentifiers.read("country-ca/ca_census_divisions").to_h(2)
  @province_and_territory_sgc_codes = OpenCivicDataIdentifiers.read("country-ca/ca_provinces_and_territories").abbreviate!.to_h(3).invert

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
end

class CensusSubdivisionIdentifier < String
  @census_subdivision_types = OpenCivicDataIdentifiers.read("country-ca/ca_census_subdivisions").to_h(2)
  @province_and_territory_sgc_codes = OpenCivicDataIdentifiers.read("country-ca/ca_provinces_and_territories").abbreviate!.to_h(3).invert

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

  # Returns the census subdivision type ID (also its SGC code).
  def census_subdivision_type_id
    self[/[^:]+\z/][0,7]
  end

  # Returns the census subdivision's type.
  def census_subdivision_type
    self.class.census_subdivision_types.fetch("ocd-division/country:ca/csd:#{census_subdivision_type_id}")
  end
end

class CensusDivisionNameMatcher
  # census_division_map.call(["on", "York"]) # "on:YORK"
  @census_division_map = lambda do |(value,name)|
    name = CensusDivisionName.new(name).normalize
    if value[/\Aocd-division/] # `value` is an OCD identifier
      identifier = CensusDivisionIdentifier.new(value)
      [identifier.province_or_territory_type_id, name.fingerprint]
    else # `value` is a province of territory type ID
      [value, name.remove_type(value).fingerprint]
    end * ":"
  end

  census_divisions = OpenCivicDataIdentifiers.read("country-ca/ca_census_divisions").mapping(0)
  @census_divisions_hash = Lycopodium.new(census_divisions, @census_division_map).reject_collisions.value_to_fingerprint.invert

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
    name = CensusSubdivisionName.new(name).normalize
    if value[/\Aocd-division/] # `value` is an OCD identifier
      identifier = CensusSubdivisionIdentifier.new(value)
      [identifier.province_or_territory_type_id, name.fingerprint]
    else # `value` is a province of territory type ID
      return nil if CensusDivisionName.new(name).has_type?(value) # skip census divisions
      [value, name.remove_type(value).fingerprint]
    end * ":"
  end

  census_subdivisions = OpenCivicDataIdentifiers.read("country-ca/ca_census_subdivisions").mapping(0)
  @census_subdivisions_hash = Lycopodium.new(census_subdivisions, @census_subdivision_map).reject_collisions.value_to_fingerprint.invert

  def self.fingerprint(province_or_territory_type_id, name)
    @census_subdivision_map.call([province_or_territory_type_id, name])
  end

  def self.identifier_and_name(fingerprint)
    @census_subdivisions_hash[fingerprint]
  end
end

class CensusSubdivisionNameTypeMatcher
  # census_subdivision_with_type_map.call(["on", "City of Toronto"]) # "on:CY:TORONTO"
  @census_subdivision_with_type_map = lambda do |(value,name)| # `value` is an OCD identifier
    name = CensusSubdivisionName.new(name).normalize
    identifier = CensusSubdivisionIdentifier.new(value)
    [identifier.province_or_territory_type_id, identifier.census_subdivision_type, name.fingerprint] * ":"
  end

  census_subdivisions = OpenCivicDataIdentifiers.read("country-ca/ca_census_subdivisions").mapping(0)
  @census_subdivisions_with_types_hash = Lycopodium.new(census_subdivisions, @census_subdivision_with_type_map).reject_collisions.value_to_fingerprint.invert

  def self.identifier_and_name(fingerprint)
    @census_subdivisions_with_types_hash[fingerprint]
  end
end
