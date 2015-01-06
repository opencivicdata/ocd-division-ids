#!/usr/bin/env ruby
# coding: utf-8

require File.expand_path(File.join("..", "utils.rb"), __FILE__)
require File.expand_path(File.join("..", "classes.rb"), __FILE__)

# Scrapes municipal subdivision names from represent.opennorth.ca
# Municipalities may correspond to census divisions or census subdivisions.

class MunicipalSubdivision < Runner
  def initialize(*args)
    super

    add_command({
      :name        => "posts-count",
      :description => "Prints a CSV of identifiers and numbers of posts",
      :output_path => "identifiers/country-ca/ca_municipal_subdivisions-posts_count.csv",
    })
    add_command({
      :name        => "has-children",
      :description => "Prints a CSV of identifiers and booleans",
      :output_path => "identifiers/country-ca/ca_municipal_subdivisions-has_children.csv",
    })
    add_command({
      :name        => "parent-id",
      :description => "Prints a CSV of identifiers and parent division",
      :output_path => "identifiers/country-ca/ca_municipal_subdivisions-parent_id.csv",
    })
    add_command({
      :name        => "data-catalog",
      :description => "Prints a CSV of identifiers and data catalog URLs",
      :output_path => "identifiers/country-ca/ca_municipal_subdivisions-data_catalog.csv",
    })
    add_command({
      :name        => "styles",
      :description => "Prints a CSV of identifiers and styles of address",
    })
  end

  def names
    ignore = OpenCivicDataIdentifiers.read("country-ca/ca_provinces_and_territories").to_h.values << "Canada"

    items = []

    JSON.load(open("http://represent.opennorth.ca/boundary-sets/?limit=0"))["objects"].each do |boundary_set|
      domain = boundary_set["domain"]
      next if ignore.include?(domain)

      subsubdivision, census_subdivision, province_or_territory = domain.match(/\A(?:([^,]+), )?([^,]+), (NL|PE|NS|NB|QC|ON|MB|SK|AB|BC|YT|NT|NU)\z/)[1..3]

      # Ignore boundary sets of boroughs.
      unless subsubdivision
        matches = census_subdivisions.fetch(province_or_territory.downcase).fetch(census_subdivision)

        census_subdivision_id = if matches.size == 1
          matches[0][:id]
        else
          # There are two Lunenburg (MD and T).
          if matches.find{|match| match[:id] == "1206001"}
            "1206001"
          # There are two L'Ange Gardien (MÉ).
          elsif matches.find{|match| match[:id] == "2482005"}
            "2482005"
          else
            matches = matches.select{|match| %w(C CY MD MÉ RCR T V TV).include?(match[:type])}
            if matches.size == 1
              matches[0][:id]
            else
              raise matches.inspect
            end
          end
        end

        items << [census_subdivision_id, boundary_set]
      end
    end

    puts CSV.generate_line(%w(id name))
    items.sort_by{|census_subdivision_id,boundary_set|
      "#{census_subdivision_id}-#{boundary_set["name"].match(/ (borough|district|division|quartier|ward)s\z/)[1]}"
    }.each do |census_subdivision_id,boundary_set|
      ocd_type = boundary_set["name"].match(/ (borough|district|division|quartier|ward)s\z/)[1]

      JSON.load(open("http://represent.opennorth.ca#{boundary_set["related"]["boundaries_url"]}?limit=0"))["objects"].sort_by{|boundary|
        identifier(boundary)
      }.each{|boundary|
        output("csd:#{census_subdivision_id}/#{ocd_type}:",
          identifier(boundary),
          boundary["name"])
      }
    end
  end

  def parent_id
    puts CSV.generate_line(%w(id parent_id))

    census_subdivisions_on.each do |identifier,block|
      output(nil, identifier, block)
    end
  end

  def data_catalog
    puts CSV.generate_line(%w(id data_catalog))

    provinces_and_territories = OpenCivicDataIdentifiers.read("country-ca/ca_provinces_and_territories").to_h.invert
    provinces_and_territories_name_fr = OpenCivicDataIdentifiers.read("country-ca/ca_provinces_and_territories-name_fr").to_h.invert

    rows = []
    CSV.parse(open("https://docs.google.com/spreadsheets/d/16fM8o7CpgEDmz-QrS6wriU7_EXV-A4DfBqo1P_XWvVM/export?gid=0&format=csv").read.force_encoding('UTF-8'), :headers => true) do |result|
      if result["tags"] && result["tags"]["canada"]
        next if [
          "British Columbia Local Government Open Data Catalogue",
          "Winnipeg, Manitoba 2010 Election",
        ].include?(result["title"])

        identifier = nil
        result["title"].sub!(" (DataBC)", "")
        match = result["title"].match(/\A(.+), (.+)\z/)
        if match
          name, province_or_territory = match[1..2]
          if provinces_and_territories.key?(province_or_territory)
            province_or_territory_type_id = provinces_and_territories.fetch(province_or_territory)[/[^:]+\z/]
          elsif provinces_and_territories_name_fr.key?(province_or_territory)
            province_or_territory_type_id = provinces_and_territories_name_fr.fetch(province_or_territory)[/[^:]+\z/]
          else
            raise "Unrecognized province or territory name: #{province_or_territory}"
          end

          if name.match(/\ARegion(?:al District)? of (.+)\z/)
            fingerprint = CensusDivisionNameMatcher.fingerprint(province_or_territory_type_id, $1)
            identifier, _ = CensusDivisionNameMatcher.identifier_and_name(fingerprint)
          else
            type = nil

            case name
            when "District of North Vancouver"
              name = "North Vancouver"
              type = "DM"
            when "Township of Langley"
              name = "Langley"
              type = "DM"
            when "Hamilton"
              type = "CY"
            end

            if type
              fingerprint = [province_or_territory_type_id, type, CensusSubdivisionName.new(name).normalize.fingerprint] * ":"
              identifier, _ = CensusSubdivisionNameTypeMatcher.identifier_and_name(fingerprint)
            else
              fingerprint = CensusSubdivisionNameMatcher.fingerprint(province_or_territory_type_id, name)
              identifier, _ = CensusSubdivisionNameMatcher.identifier_and_name(fingerprint)
            end
          end
        elsif provinces_and_territories[result["title"]]
          identifier = provinces_and_territories[result["title"]]
        elsif provinces_and_territories_name_fr[result["title"]]
          identifier = provinces_and_territories_name_fr[result["title"]]
        elsif result["title"] == "Canada"
          identifier = "ocd-division/country:ca"
        else
          raise "Unrecognized data catalog name: #{result["title"]}"
        end

        if identifier
          rows << [nil, identifier, result["url"]]
        else
          $stderr.puts fingerprint
        end
      end
    end

    rows.sort_by{|_,identifier,_| identifier}.each do |args|
      output(*args)
    end
  end

  # Asked Ontario:
  # 2014-02-20 JShiu@amo.on.ca "I believe we do not have a report that lists this type of information."
  # 2014-02-18 amcto@amcto.com "we do not maintain a list of council seats within each municipality"
  # 2014-02-18 mininfo.mah@ontario.ca "We regret to inform you that we cannot assist on this matter."
  # 2014-02-24 info@elections.on.ca "Elections Ontario does not have that information to provide."
  def posts_count
    puts CSV.generate_line(%w(id posts_count))

    # @see http://www.novascotia.ca/snsmr/municipal/government/elections.asp
    # The spreadsheet and roo gems open the Excel file too slowly.
    Tempfile.open("data.xls") do |f|
      f.binmode
      open("http://www.novascotia.ca/dma/pdf/mun-municipal-election-results-2008-2012.xls") do |data|
        f.write(data.read)
      end

      type = "RGM"
      Spreadsheet.open(f.path).worksheet(1).each do |row|
        case row[0]
        when "Amherst" # top of list
          type = "T"
        when "Annapolis" # top of list
          type = "MD"
        end

        if row[0] && row[1] && row[0].strip != "Voter Turnout"
          identifier = nil
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

          output(nil, identifier, Integer(row[1].value))
        end
      end
    end

    # donnees.electionsmunicipales.gouv.qc.ca is no longer available.
    # @see http://donnees.electionsmunicipales.gouv.qc.ca/
    # CSV.parse(open("http://donnees.electionsmunicipales.gouv.qc.ca/liste_municipalites.csv"), :col_sep => ";", :headers => true) do |row|
    #   output("csd:",
    #     "24#{row["id_ville"]}",
    #     JSON.load(open("http://donnees.electionsmunicipales.gouv.qc.ca/#{row["id_ville"]}.json"))["ville"]["postes"].size)
    # end

    bc_type_map = {
      'District' => 'DM',
      'City' => 'CY',
      'Village' => 'VL',
      'Island Municipality' => 'IM',
      'Town' => 'T',
      'Township' => 'DM',
      'Regional Municipality' => 'RGM',
      'Mountain Resort Municipality' => 'VL',
      'Resort Municipality' => 'DM',
    }

    bc_name_map = {
      'Sun Peaks' => 'Sun Peaks Mountain',
    }

    data = Hash.new(0)
    CSV.parse(open("http://www.election2014.civicinfo.bc.ca/2014/reports/report_adv_results.asp?excel=yes&etype=%27MAYOR%27,%20%27COUNCILLOR%27"), :headers => true) do |row|
      data[[row['Local Government'], row['Jurisdiction Type']]] += 1
    end

    data.each do |(name,type),count|
      fingerprint = ["bc", bc_type_map[type], CensusSubdivisionName.new(bc_name_map.fetch(name, name)).normalize.fingerprint] * ":"
      identifier, _ = CensusSubdivisionNameTypeMatcher.identifier_and_name(fingerprint)
      if identifier
        output(nil, identifier, count)
      else
        raise fingerprint
      end
    end
  end

  # Asked Ontario:
  # 2014-02-11 amo@amo.on.ca "After reviewing our election data we found that we have not been tracking election results by wards so are unable to compile a list of municipalities that have wards."
  # 2014-02-18 amcto@amcto.com "we are unable to provide individual responses from municipalities as a means to respect the confidentiality of their responses"
  # 2014-02-11 mininfo.mah@ontario.ca "We regret to inform you that we do not have the information you requested."
  # 2014-02-24 info@elections.on.ca "Elections Ontario does not have that information to provide."
  # 2014-03-17 ontario.municipal.board@ontario.ca "The Board does not have such a list. The OMB is an adjudicative tribunal that deals with appeals and applications."
  # @see http://www.e-laws.gov.on.ca/html/statutes/english/elaws_statutes_01m25_e.htm#BK238
  # @see http://m.mpac.ca/about/corporate_overview/department.asp
  # @see https://www.omb.gov.on.ca/stellent/groups/public/@abcs/@www/@omb/documents/webasset/ec082186.pdf
  # Asked Manitoba:
  # 2014-04-09 mmaa@mymts.net "You would have to call the Municipal department."
  # 2014-04-11 amm@amm.mb.ca jgreen@amm.mb.ca "We do not have such information for each municipality."
  # 2014-04-14 election@elections.mb.ca MRobertson@elections.mb.ca "I'm sorry but Elections Manitoba does not have this type of information."
  # 2014-04-14 mgi@gov.mb.ca Linda.Baleja@gov.mb.ca "We do not compile this information."
  # 2014-04-30 MLInfo@gov.mb.ca "You might try "Elections Manitoba" at (204) 945-5635"
  # MB: "Contact your local municipal office to find out whether a ward by-law is in place in your municipality."
  # @see http://web5.gov.mb.ca/mfas/elections_faq.aspx#voters_q4
  # @see http://web2.gov.mb.ca/laws/statutes/ccsm/m225e.php#87
  # Asked Saskatchewan for boundary files:
  # 2014-03-21 ask@isc.ca John.Leonard@isc.ca "As far as anything within the RM’s such as their division boundaries we don’t have them."
  # 2014-03-24 muninfo@gov.sk.ca "Government Relations doesn't have RM maps."
  def has_children
    subdivisions = Hash.new("N")

    # http://www.novascotia.ca/snsmr/municipal/government/elections.asp
    # The spreadsheet and roo gems open the Excel file too slowly.
    Tempfile.open("data.xls") do |f|
      f.binmode
      open("http://www.novascotia.ca/dma/pdf/mun-municipal-election-results-2008-2012.xls") do |data|
        f.write(data.read)
      end

      type = nil
      name = nil
      Spreadsheet.open(f.path).worksheet(4).each do |row|
        case row[0]
        when "Regional Municipalities"
          type = "RGM"
        when "Town"
          type = "T"
        when "Municipalities"
          type = "MD"
        end

        # Process municipalities with districts. Skip the header row.
        if row[0] && row[1] && row[0].strip != "Municipality"
          next if row[0] == name
          name = row[0]

          value = row[0].sub(" (County)", "")
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

          if identifier
            subdivisions[identifier] = "Y"
          else
            raise fingerprint
          end
        end
      end
    end

    boroughs = [
      "Lévis",
      "Longueuil",
      "Montréal",
      "Québec",
      "Saguenay",
      "Sherbrooke",
    ]
    type_map = {
      "CT" => "CT",
      "M"  => "MÉ",
      "P"  => "PE",
      "V"  => "V",
      "VL" => "VL",
    }
    Nokogiri::HTML(open("http://www.electionsquebec.qc.ca/francais/municipal/carte-electorale/liste-des-municipalites-divisees-en-districts-electoraux.php?index=1")).xpath("//div[@class='indente zone-contenu']/div[@class='boite-grise']//text()").each do |node|
      text = node.text.strip
      unless text.empty? || text == ", V"
        if boroughs.include?(text)
          name, type = text, "V"
        else
          name, type = text.match(/\A(.+), (.+)\z/)[1..2]
        end

        if type == 'M' && ['Calixa-Lavallée', 'Saint-Ambroise-de-Kildare', 'Saint-Justin'].include?(name)
          type = 'P'
        end

        fingerprint = ["qc", type_map.fetch(type), CensusSubdivisionName.new(name).normalize.fingerprint] * ":"
        identifier, _ = CensusSubdivisionNameTypeMatcher.identifier_and_name(fingerprint)

        if identifier
          subdivisions[identifier] = "Y"
        elsif name == "L'Ange-Gardien" # two subdivisions match
          subdivisions["ocd-division/country:ca/csd:2482005"] = "Y"
        else
          raise fingerprint
        end
      end
    end

    # Some Québec municipalities are divided into "quartiers" instead of
    # "districts" (Mireille Loignon <Mloignon@dgeq.qc.ca> 2014-02-07).
    [ "2402015", # Grande-Rivière
      "2403005", # Gaspé
      "2411040", # Trois-Pistole
      "2413095", # Pohénégamook
      "2434120", # Lac-Sergent
      "2446080", # Cowansville
      "2453050", # Saint-Joseph-de-Sorel
      "2467025", # Delson
      "2469055", # Huntingdon
      "2487090", # La Sarre
      "2483065", # Maniwaki
      "2489040", # Senneterre
      "2493005", # Desbiens
    ].each do |identifier|
      subdivisions["ocd-division/country:ca/csd:#{identifier}"] = "Y"
    end

    census_subdivisions_sk.each do |identifier,block|
      if block[/^Division \d+:/]
        subdivisions[identifier] = "Y"
      end
    end

    # These may opt to adopt wards in the future (2014-02-10). Check manually.
    alberta_cities_without_subdivisions = [
      "4801006", # Medicine Hat
      "4802012", # Lethbridge
      "4802034", # Brooks
      "4806021", # Airdrie
      "4808011", # Red Deer
      "4808031", # Lacombe
      "4810011", # Camrose
      "4810039", # Lloydminster
      "4811002", # Wetaskiwin
      "4811016", # Leduc
      "4811049", # Spruce Grove
      "4811056", # Fort Saskatchewan
      "4811062", # St. Albert
      "4812002", # Cold Lake
      "4815007", # Crowsnest Pass
      "4815033", # Jasper
      "4819012", # Grande Prairie
    ]
    # These two lists are a complete list of all cities in Alberta.
    alberta_cities_with_subdivisions = [
      "4806016", # Calgary
      "4811052", # Strathcona County
      "4811061", # Edmonton
      "4816037", # Wood Buffalo
      "4817095", # Mackenzie County
    ]

    puts CSV.generate_line(%w(id has_children))

    OpenCivicDataIdentifiers.read("country-ca/ca_census_divisions").each do |identifier,name,name_fr,classification|
      if identifier[/[^:]+\z/][0, 2] == "12"
        output(nil, identifier, subdivisions[identifier])
      end
    end

    OpenCivicDataIdentifiers.read("country-ca/ca_census_subdivisions").each do |identifier,name,name_fr,classification,organization_name|
      type_id = identifier[/[^:]+\z/]
      if %w(IRI NO S-É SNO).include?(classification)
        output(nil, identifier, "N")
      else
        case type_id[0, 2]
        # 2014-04-09 ashleydavis@gov.nl.ca
        when "10"
          if [
            "1001485", # Conception Bay South
            "1001519", # St. John's
            "1009007", # Roddickton-Bide Arm
            "1007060", # New-Wes-Valley
            ].include?(type_id)
            output(nil, identifier, "Y")
          else
            output(nil, identifier, "N")
          end
        # 2014-03-24 jgrichard@electionspei.ca
        # @see http://www.electionspei.ca/municipal/wards/
        # @see http://www.electionspei.ca/index.php?number=1046804&lang=E
        when "11"
          if [
            "1102075", # Charlottetown
            "1102080", # Stratford
            "1103025", # Summerside
          ].include?(type_id)
            output(nil, identifier, "Y")
          else
            output(nil, identifier, "N")
          end
        # @see http://geonb.snb.ca/ArcGIS/rest/services/ElectionsNB/GeoNB_ENB_MunicipalWards/MapServer
        when "13"
          if [
            "1301006", # Saint John
            "1302004", # Campobello Island
            "1303012", # Oromocto
            "1306020", # Riverview
            "1307005", # Beaubassin East
            "1307013", # Memramcook
            "1307022", # Moncton
            "1307045", # Dieppe
            "1309027", # Upper Miramichi
            "1310032", # Fredericton
            "1311027", # Florenceville-Bristol
            "1312019", # Grand Falls
            "1313002", # Saint-André
            "1313027", # Edmundston
            "1314019", # Kedgwick
            "1314025", # Belledune
            "1315015", # Beresford
            "1315027", # Bas-Caraquet
            "1315028", # Caraquet
          ].include?(type_id)
            output(nil, identifier, "Y")
          else
            output(nil, identifier, "N")
          end
        when "12", "24"
          output(nil, identifier, subdivisions[identifier])
        when "47"
          output(nil, identifier, subdivisions[identifier])
        # @see http://www.municipalaffairs.gov.ab.ca/am_types_of_municipalities_in_alberta.cfm
        when "48"
          value = case classification
          when "CY", "SM"
            if alberta_cities_without_subdivisions.include?(type_id)
              "N"
            elsif alberta_cities_with_subdivisions.include?(type_id)
              "Y"
            else
              raise "Couldn't determine subdivisions: #{type_id}"
            end
          when "MD"
            "Y"
          when "ID", "IRI", "S-É", "SA", "SV", "T", "VL"
            "N"
          else
            raise "Unrecognized census subdivision type: #{classification}"
          end
          output(nil, identifier, value)
        when "59"
          output(nil, identifier, "N")
        end
      end
    end
  end

  def styles
    census_subdivisions_sk.each do |identifier,block|
      # Subdivisions with a population of less than 42 may not list elected officials.
      raise_if_error = Integer(block[/^Population: +([\d,]+)$/, 1].sub(",", "")) > 42

      leader = nil
      member = nil

      if block[/^(Chairman|Mayor|Reeve):/]
        leader = $1
      elsif raise_if_error
        raise "Unrecognized style of address: #{block}"
      end

      if block[/^(Alderman|Councillor|Member):/]
        member = $1
      elsif block[/^Division \d+:/]
        member = "Councillor"
      elsif raise_if_error
        raise "Unrecognized style of address: #{block}"
      end

      if leader && member
        puts "#{identifier},#{leader},#{member}"
      elsif leader || member
        raise "Only determined one style of address: #{block}"
      end
    end

    census_subdivisions_on.each do |identifier,_|
      # Not sure if all these have people whose only role is Regional Councillor.
      puts "#{identifier},Mayor,Councillor,Regional Councillor"
    end
  end

private

  def identifier(boundary)
    if boundary["external_id"].empty?
      boundary["name"]
    elsif boundary["external_id"][/\A[\d.]+\z/]
      boundary["external_id"].to_i
    else
      boundary["external_id"]
    end
  end

  def type_map(province_or_territory = nil)
    {}.tap do |hash|
      indexes = {
        "nl" => 2,
        "pe" => 3,
        "ns" => 4,
        "nb" => 5,
        "qc" => 6,
        "on" => 7,
        "mb" => 8,
        "sk" => 9,
        "ab" => 10,
        "bc" => 11,
        "yt" => 12,
        "nt" => 13,
        "nu" => 14,
      }

      {"cd" => 4, "csd" => 5}.each do |type,table|
        hash[type] = {}
        Nokogiri::HTML(open("http://www12.statcan.gc.ca/census-recensement/2011/ref/dict/table-tableau/table-tableau-#{table}-eng.cfm")).xpath("//table/tbody/tr").each do |row|
          abbr = row.at_xpath("./th[1]/abbr")
          if abbr
            unless province_or_territory && row.at_xpath("./td[#{indexes[province_or_territory]}]/abbr") || province_or_territory == "on" && abbr.text == "TV" # Skip the one TV in Ontario
              hash[type][abbr["title"].sub(/ \/.+\z/, "").split.map(&:capitalize).join(" ")] = abbr.text
              hash[type][abbr.text] = abbr.text
            end
          end
        end
      end

      hash["csd"]["United Townships"] = "TP" # Ontario: Dysart and Others
      hash["csd"]["Northern Town"] = "T" # Saskatchewan
    end
  end

  def census_subdivisions
    @census_subdivisions ||= {}.tap do |hash|
      OpenCivicDataIdentifiers.read("country-ca/ca_census_subdivisions").each do |identifier,name,name_fr,classification,organization_name|
        type_id = identifier[/[^:]+\z/]
        object = CensusSubdivisionIdentifier.new(type_id)
        key = object.province_or_territory_type_id
        hash[key] ||= {}
        hash[key][name] ||= []
        hash[key][name] << {:id => type_id, :type => classification}
      end
    end
  end

  def census_subdivisions_on
    blocks = {}

    type_map = type_map("on")

    Nokogiri::HTML(open("http://www.mah.gov.on.ca/Page1591.aspx").read).xpath("//table[1]//tr[position()>1]").each do |row|
      text = row.xpath(".//td[1]").text.strip.normalize_space
      if row.xpath(".//td[2]").text.strip == "Lower Tier"
        text_map = {
          "Grand Valley, Town of"             => ["East Luther Grand Valley", "Township"],
          "Markham, City of"                  => ["Markham", "Town"],
          "Middlesex Centre, Municipality of" => ["Middlesex Centre", "Township"],
          "Selwyn, Township of"               => ["Smith-Ennismore-Lakefield", "Township"],
          "South Dundas, Municipality of"     => ["South Dundas", "Township"],
          "Trent Lakes, Municipality of"      => ["Galway-Cavendish and Harvey", "Township"],
        }

        if ["Haldimand County", "Norfolk County"].include?(text)
          name = text
          type_name = "City"
        elsif text_map.key?(text)
          name, type_name = text_map[text]
        elsif text[","]
          name, type_name = text.match(/\A(.+), (.+) of\z/)[1..2]
        else
          name, type_name = text.match(/\A(.+) (Municipality)\z/)[1..2]
        end

        type = type_map["cd"][type_name] || type_map["csd"][type_name] || raise("Unrecognized type name: '#{type_name}'")

        if name == "Dysart, Dudley, Harcourt, Guilford, Harburn, Bruton, Havelock, Eyre and Clyde"
          name = "Dysart and Others"
        end
        if name == "The Nation"
          type = "M" # not MU
        end

        fingerprint = ["on", type, CensusSubdivisionName.new(name).normalize.fingerprint] * ":"
        identifier, _ = CensusSubdivisionNameTypeMatcher.identifier_and_name(fingerprint)

        unless identifier
          fingerprint = ["on", type, CensusDivisionName.new(name).normalize.fingerprint] * ":"
          identifier, _ = CensusDivisionNameTypeMatcher.identifier_and_name(fingerprint)
        end

        census_division_fingerprint = CensusDivisionNameMatcher.fingerprint("on", row.xpath(".//td[3]").text.strip)
        census_division_identifier, _ = CensusDivisionNameMatcher.identifier_and_name(census_division_fingerprint)

        if identifier && census_division_identifier
          blocks[identifier] = census_division_identifier
        elsif identifier
          raise census_division_fingerprint
        else
          raise fingerprint
        end
      end
    end

    blocks
  end

  def census_subdivisions_sk
    blocks = {}

    type_map = type_map("sk")

    saskatchewan_non_census_subdivisions = [
      # @see http://en.wikipedia.org/wiki/Division_No._18,_Saskatchewan#Unincorporated_communities
      # @see http://en.wikipedia.org/wiki/Category:Division_No._18,_Unorganized,_Saskatchewan
      "BEAR CREEK",
      "BLACK POINT",
      "CAMSELL PORTAGE",
      "DESCHARME LAKE",
      "GARSON LAKE",
      "SLED LAKE",
      "SOUTHEND",
      "STANLEY MISSION",
      "URANIUM CITY",
      "WOLLASTON LAKE",
    ]

    # Select "Entire Directory" and click "Generate PDF".
    # @see http://www.mds.gov.sk.ca/apps/Pub/MDS/welcome.aspx
    # @see http://www.qp.gov.sk.ca/documents/English/Statutes/Statutes/M36-1.pdf
    agent = Mechanize.new
    page = agent.get("http://www.mds.gov.sk.ca/apps/Pub/MDS/welcome.aspx")
    page.forms[0]["txtPDF"] = "1"
    page.forms[0]["__EVENTTARGET"] = "btnGeneratePDF"
    page.forms[0]["__EVENTARGUMENT"] = ""
    page.forms[0]["__EVENTVALIDATION"] = page.parser.at_xpath("//input[@id='__EVENTVALIDATION']/@value").text
    page.forms[0]["drpDownList"] = "0"
    page = page.forms[0].submit

    pdf = Tempfile.open("census_subdivisions_sk") do |f|
      f.binmode
      f.write(open("http://www.mds.gov.sk.ca/apps/#{page.body[%r{temp/[^']+}]}").read)
      f
    end

    header_re = /^\f?(?:CITIES|NORTHERN TOWNS, VILLAGES, HAMLETS, AND SETTLEMENTS|ORGANIZED AND RESORT HAMLETS|RURAL MUNICIPALITIES|TOWNS, VILLAGES AND RESORT VILLAGES|UNKNOWN)/
    footer_re = /^                                       *Page \d+ of 23\d/
    pages = []
    page = []

    # Group the lines into pages.
    maximum_line_length = 0
    `pdftotext -layout #{pdf.path} -`.split("\n").each do |line|
      # Skip headers.
      next if line[header_re]

      line_length = line.size
      if line_length > maximum_line_length
        maximum_line_length = line_length
      end

      if line[footer_re]
        pages << page
        page = []
      else
        page << line
      end
    end

    column_divider_re = /(?<=  )\S/
    text = []

    # Transform the text of each page into a single column.
    pages.each do |page|
      index = maximum_line_length
      page.each do |line|
        # Skip new lines and address lines.
        next if line == "" || line[/^                ?\S/]

        match = line.match(column_divider_re, 46) # True indices first appear at 46.
        if match
          start = match.begin(0)
          if start < index
            index = start
          end
        end
      end

      column1 = []
      column2 = []
      page.each do |line|
        column1 << line[0...index].strip
        part = line[index..-1]
        if part
          column2 << part.strip
        else
          column2 << ""
        end
      end
      text += column1
      text += column2
    end

    # Split the text into blocks, one per subdivision.
    text.join("\n").split(/\n\n\n+/).each do |block|
      line = block.strip.split("\n").first

      if line [/^Village of (.+),/]
        name = $1
        type = "VL"
      elsif line[/^(.+), (.+?)(?: of)?$/]
        name = $1
        type = $2
      elsif line[/^RM of (.+)$/]
        name = $1
        type = "RM"
      end

      next if ["Northern Hamlet", "Northern Settlement"].include?(type) && saskatchewan_non_census_subdivisions.include?(name)

      name.sub!(/\bDISTRICT OF /, "")
      identifier = nil

      if ["Hamlet", "Organized Hamlet", "Special Service Area"].include?(type)
        fingerprint = CensusSubdivisionNameMatcher.fingerprint("sk", name)
        identifier, _ = CensusSubdivisionNameMatcher.identifier_and_name(fingerprint)
        if identifier
          raise "Unexpected matching census subdivision for #{name} (#{type})"
        else
          next
        end
      end

      if ["Northern Hamlet", "Northern Settlement"].include?(type)
        fingerprint = CensusSubdivisionNameMatcher.fingerprint("sk", name)
        identifier, _ = CensusSubdivisionNameMatcher.identifier_and_name(fingerprint)
        unless identifier
          raise "Expected matching census subdivision for #{name} (#{type})"
        end
      end

      unless identifier
        # Some census subdivisions changed type since 2011.
        if name == "WARMAN" && type == "City"
          census_subdivision_type = "T"
        elsif ["HEPBURN", "PENSE"].include?(name) && type == "Town"
          census_subdivision_type = "VL"
        else
          census_subdivision_type = type_map["csd"].fetch(type)
        end

        fingerprint = ["sk", census_subdivision_type, CensusSubdivisionName.new(name).normalize.fingerprint] * ":"
        identifier, _ = CensusSubdivisionNameTypeMatcher.identifier_and_name(fingerprint)
      end

      unless identifier
        raise fingerprint
      end

      blocks[identifier] = block
    end

    blocks
  end
end

MunicipalSubdivision.new("ca_municipal_subdivisions.csv").run(ARGV)
