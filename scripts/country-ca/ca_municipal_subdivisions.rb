#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)
require File.expand_path(File.join("..", "classes.rb"), __FILE__)

# Scrapes municipal subdivision names from represent.opennorth.ca
# Municipalities may correspond to census divisions or census subdivisions.

require "json"
require "tempfile"
require "nokogiri"

class MunicipalSubdivision < Runner
  @csv_filename = "ca_municipal_subdivisions.csv"
  @translatable = false

  def initialize
    super

    add_command({
      :name        => "corporations",
      :description => "Prints a CSV of identifiers and municipal corporation names",
      :directory   => "mappings/country-ca-corporations",
    })
    add_command({
      :name        => "posts",
      :description => "Prints a CSV of identifiers and numbers of posts",
      :directory   => "mappings/country-ca-posts",
    })
    add_command({
      :name        => "subdivisions",
      :description => "Prints a CSV of identifiers and booleans",
      :directory   => "mappings/country-ca-subdivisions",
    })
  end

  def names
    ignore = OpenCivicDataIdentifiers.read("country-ca/ca_provinces_and_territories").to_h.values << "Canada"

    items = []

    JSON.load(open("http://represent.opennorth.ca/boundary-sets/?limit=0"))["objects"].each do |boundary_set|
      domain = boundary_set["domain"]
      next if ignore.include?(domain)

      subsubdivision, census_subdivision, province_or_territory = domain.match(/\A(?:([^,]+), )?([^,]+), (NL|PE|NS|NB|QC|ON|MB|SK|AB|BC|YT|NT|NU)\z/)[1..3]

      # Ignore municipal subsubdivisions. Montréal subdivisions are handled by another script.
      unless subsubdivision || census_subdivision == 'Montréal'
        matches = census_subdivisions.fetch(province_or_territory.downcase).fetch(census_subdivision)

        census_subdivision_id = if matches.size == 1
          matches[0][:id]
        else
          matches.find{|match| match[:type] == "CY"}[:id]
        end

        items << [census_subdivision_id, boundary_set]
      end
    end

    items.sort_by(&:first).each do |census_subdivision_id,boundary_set|
      ocd_type = boundary_set["name"].match(/ (borough|district|division|ward)s\z/)[1]

      JSON.load(open("http://represent.opennorth.ca#{boundary_set["related"]["boundaries_url"]}?limit=0"))["objects"].sort_by{|boundary|
        identifier(boundary)
      }.each{|boundary|
        output("csd:#{census_subdivision_id}/#{ocd_type}:",
          identifier(boundary),
          boundary["name"])
      }
    end
  end

  def corporations
    exceptions = {
      "ocd-division/country:ca/csd:4819006" => "County of Grande Prairie No. 1",
      "ocd-division/country:ca/csd:3519036" => "City of Markham",  # became a city since 2011
      "ocd-division/country:ca/csd:3528018" => "Corporation of Haldimand County",
      # SM: Specialized municipality
      "ocd-division/country:ca/csd:4811052" => "Strathcona County",
      "ocd-division/country:ca/csd:4815007" => "Municipality of Crowsnest Pass",
      "ocd-division/country:ca/csd:4815033" => "Municipality of Jasper",
      "ocd-division/country:ca/csd:4816037" => "Regional Municipality of Wood Buffalo",
      "ocd-division/country:ca/csd:4817095" => "Mackenzie County",
    }

    names = {}
    %w(ca_census_divisions ca_census_subdivisions).each do |filename|
      OpenCivicDataIdentifiers.read("country-ca/#{filename}").each do |identifier,name|
        names[identifier] = name
      end
    end

    type_names = {}
    { "ca_census_divisions" => 4,
      "ca_census_subdivisions" => 5,
    }.each do |filename,table|
      type_names[filename] = {}
      Nokogiri::HTML(open("http://www12.statcan.gc.ca/census-recensement/2011/ref/dict/table-tableau/table-tableau-#{table}-eng.cfm")).xpath("//table/tbody/tr/th[1]/abbr").each do |abbr|
        type_names[filename][abbr.text] = abbr['title'].sub(/ \/.+\z/, '')
      end
    end

    %w(ca_census_divisions ca_census_subdivisions).each do |filename|
      OpenCivicDataMappings.read("country-ca-types/#{filename}").each do |identifier,mapping|
        type_id = identifier[/[^:]+\z/]
        if exceptions.key?(identifier)
          output("csd:", type_id.to_i, exceptions[identifier])
        else
          case mapping
          when "RGM"
            name = "#{names[identifier]} Regional Municipality"
            output(filename == "ca_census_divisions" ? "cd:" : "csd:", type_id.to_i, name)
          when "C", "CV", "CY", "MD", "MU", "T", "TP", "V", "VL"
            name = "#{type_names[filename][mapping]} #{type_id[0, 2] == "24" ? "de" : "of"} #{names[identifier]}"
            output(filename == "ca_census_divisions" ? "cd:" : "csd:", type_id.to_i, name)
          end
        end
      end
    end
  end

  def posts
    # http://www.novascotia.ca/snsmr/municipal/government/elections.asp
    # The spreadsheet and roo gems open the Excel file too slowly.
    Tempfile.open("data.xls") do |f|
      f.binmode
      open("http://www.novascotia.ca/snsmr/pdf/mun-municipal-election-results-2008-2012.xls") do |data|
        f.write(data.read)
      end
      sheet = `xls2csv #{f.path}`.split("\f")[1]

      type = "RGM"
      CSV.parse(sheet) do |row|
        case row[0]
        when "Amherst" # top of list
          type = "T"
        when "Annapolis" # top of list
          type = "MD"
        end

        if row[0] && row[1] && row[0].strip != 'Voter Turnout'
          if type != "MD"
            fingerprint = CensusSubdivisionNameMatcher.fingerprint("ns", row[0])
            identifier, _ = CensusSubdivisionNameMatcher.identifier_and_name(fingerprint)
          end
          unless identifier
            fingerprint = ["ns", type, CensusSubdivisionName.new(row[0]).normalize.fingerprint] * ":"
            identifier, _ = CensusSubdivisionNameTypeMatcher.identifier_and_name(fingerprint)
          end
          unless identifier
            fingerprint = CensusDivisionNameMatcher.fingerprint("ns", row[0])
            identifier, _ = CensusDivisionNameMatcher.identifier_and_name(fingerprint)
          end

          type_id = identifier[/[^:]+\z/]
          fragment = type_id.size == 4 ? "cd:" : "csd:"
          output(fragment, type_id.to_i, row[1])
        end
      end
    end
  end

  # ON: Asked ontario.municipal.board@ontario.ca, enquiry@mpac.ca (2014-02-10), amcto@amcto.com (2014-02-11).
  # 2014-02-11 mininfo.mah@ontario.ca "We regret to inform you that we do not have the information you requested."
  # 2014-02-11 amo@amo.on.ca "After reviewing our election data we found that we have not been tracking election results by wards so are unable to compile a list of municipalities that have wards."
  # @see http://www.e-laws.gov.on.ca/html/statutes/english/elaws_statutes_01m25_e.htm#BK238
  # @see http://m.mpac.ca/about/corporate_overview/department.asp
  # @see https://www.omb.gov.on.ca/stellent/groups/public/@abcs/@www/@omb/documents/webasset/ec082186.pdf
  # MB: "Contact your local municipal office to find out whether a ward by-law is in place in your municipality."
  # @see http://web5.gov.mb.ca/mfas/elections_faq.aspx#voters_q4
  # @see http://web2.gov.mb.ca/laws/statutes/ccsm/m225e.php#87
  def subdivisions
    type_map = {
      "CT" => "CT",
      "M"  => "MÉ",
      "P"  => "PE",
      "V"  => "V",
      "VL" => "VL",
    }

    boroughs = [
      "Lévis",
      "Longueuil",
      "Montréal",
      "Québec",
      "Saguenay",
      "Sherbrooke",
    ]

    subdivisions = Hash.new("N")

    # http://www.novascotia.ca/snsmr/municipal/government/elections.asp
    # The spreadsheet and roo gems open the Excel file too slowly.
    Tempfile.open("data.xls") do |f|
      f.binmode
      open("http://www.novascotia.ca/snsmr/pdf/mun-municipal-election-results-2008-2012.xls") do |data|
        f.write(data.read)
      end
      sheet = `xls2csv #{f.path}`.split("\f")[4]

      type = nil
      name = nil
      CSV.parse(sheet) do |row|
        case row[0]
        when "Regional Municipalities"
          type = "RGM"
        when "Town"
          type = "T"
        when "Municipalities"
          type = "MD"
        end

        if row[0] && row[1] && row[0].strip != 'Municipality'
          next if row[0] == name
          name = row[0]

          value = row[0].sub(' (County)', '')
          identifier = nil

          if !row[0][/ \(County\)\z/]
            fingerprint = CensusSubdivisionNameMatcher.fingerprint("ns", value)
            identifier, _ = CensusSubdivisionNameMatcher.identifier_and_name(fingerprint)
          end
          unless identifier
            fingerprint = ["ns", type, CensusSubdivisionName.new(value).normalize.fingerprint] * ":"
            identifier, _ = CensusSubdivisionNameTypeMatcher.identifier_and_name(fingerprint)
          end
          unless identifier
            fingerprint = CensusDivisionNameMatcher.fingerprint("ns", value)
            identifier, _ = CensusDivisionNameMatcher.identifier_and_name(fingerprint)
          end

          subdivisions[identifier] = "Y"
        end
      end
    end

    Nokogiri::HTML(open("http://www.electionsquebec.qc.ca/francais/municipal/carte-electorale/liste-des-municipalites-divisees-en-districts-electoraux.php?index=1")).xpath('//div[@class="indente zone-contenu"]/div[@class="boite-grise"]//text()').each do |node|
      text = node.text.strip
      unless text.empty? || text == ", V"
        if boroughs.include?(text)
          name, type = text, "V"
        else
          name, type = text.match(/\A(.+), (.+)\z/)[1..2]
        end

        fingerprint = ["qc", type_map.fetch(type), CensusSubdivisionName.new(name).normalize.fingerprint] * ":"
        identifier, _ = CensusSubdivisionNameTypeMatcher.identifier_and_name(fingerprint)

        if identifier
          subdivisions[identifier] = "Y"
        elsif text != "L'Ange-Gardien, M" # two census subdivisions match
          raise fingerprint
        end
      end
    end

    # Some Québec municipalities are divided into "quartiers" instead of
    # "districts". (Mireille Loignon <Mloignon@dgeq.qc.ca>)
    [ '2402015', # Grande-Rivière
      '2403005', # Gaspé
      '2411040', # Trois-Pistole
      '2413095', # Pohénégamook
      '2434120', # Lac-Sergent
      '2446080', # Cowansville
      '2453050', # Saint-Joseph-de-Sorel
      '2467025', # Delson
      '2469055', # Huntingdon
      '2487090', # La Sarre
      '2483065', # Maniwaki
      '2489040', # Senneterre
      '2493005', # Desbiens
    ].each do |identifier|
      subdivisions["ocd-division/country:ca/csd:#{identifier}"] = "Y"
    end

    # These cities may opt to adopt wards in the future.
    alberta_cities_without_subdivisions = %w(
      4801006
      4802012
      4802034
      4806021
      4808011
      4808031
      4810011
      4811002
      4811016
      4811049
      4811056
      4811062
      4812002
      4819012
    )

    types = {}
    OpenCivicDataMappings.read("country-ca-types/ca_census_subdivisions").each do |identifier,mapping|
      types[identifier] = mapping
    end

    OpenCivicDataIdentifiers.read("country-ca/ca_census_divisions").each do |identifier,_|
      type_id = identifier[/[^:]+\z/]
      if type_id[0, 2] == "12"
        output("csd:", type_id.to_i, subdivisions[identifier])
      end
    end

    OpenCivicDataIdentifiers.read("country-ca/ca_census_subdivisions").each do |identifier,_|
      type_id = identifier[/[^:]+\z/]
      if %w(IRI NO SNO).include?(types[identifier])
        output("csd:", type_id.to_i, "N")
      else
        case type_id[0, 2]
        when "12", "24"
          output("csd:", type_id.to_i, subdivisions[identifier])
        # @see http://www.qp.gov.sk.ca/documents/English/Statutes/Statutes/M36-1.pdf
        when "47"
          if types[identifier] == "RM"
            output("csd:", type_id.to_i, "N")
          end
        # @see http://www.municipalaffairs.gov.ab.ca/am_types_of_municipalities_in_alberta.cfm
        when "48"
          value = case types[identifier]
          when "CY", "SM"
            alberta_cities_without_subdivisions.include?(type_id) ? "N": "?"
          when "MD"
            "Y"
          when "ID", "IRI", "S-É", "SA", "SV", "T", "VL"
            "N"
          else
            raise "Unrecognized census subdivision type: #{types[identifier]}"
          end
          output("csd:", type_id.to_i, value)
        when "59"
          output("csd:", type_id.to_i, "N")
        end
      end
    end
  end

private

  def census_subdivisions
    @census_subdivisions ||= {}.tap do |hash|
      OpenCivicDataIdentifiers.read("country-ca/ca_census_subdivisions").abbreviate!.each do |identifier,value|
        object = CensusSubdivisionIdentifier.new(identifier)
        key = object.province_or_territory_type_id
        hash[key] ||= {}
        hash[key][value] ||= []
        hash[key][value] << {:id => identifier, :type => object.census_subdivision_type}
      end
    end
  end

  def identifier(boundary)
    if boundary["external_id"].empty?
      boundary["name"]
    else
      boundary["external_id"].to_i
    end
  end
end

MunicipalSubdivision.new.run(ARGV)
