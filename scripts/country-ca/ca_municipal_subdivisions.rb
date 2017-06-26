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
      :name        => "styles",
      :description => "Prints a CSV of identifiers and styles of address",
    })
  end

  def names
    provinces_and_territories = OpenCivicDataIdentifiers.read("country-ca/ca_provinces_and_territories").to_h
    domain_re = /\A(?:([^,]+), )?([^,]+), (#{provinces_and_territories.keys.map{|id| id.split(":")[-1].upcase}.join("|")})\z/
    ignore = provinces_and_territories.values << "Canada"

    items = []

    JSON.load(open("https://represent.opennorth.ca/boundary-sets/?limit=0"))["objects"].each do |boundary_set|
      # Skip boundary sets that are mergers of others.
      next if boundary_set["url"] == "/boundary-sets/montreal-boroughs-and-districts/"

      # Skip federal, provincial and territorial boundary sets.
      domain = boundary_set["domain"]
      next if ignore.include?(domain)

      # Skip a borough's districts, which are already imported as its municipality's districts.
      subsubdivision, geographic_name, province_or_territory = domain.match(domain_re)[1..3]
      next if subsubdivision

      matches = census_subdivisions.fetch(province_or_territory.downcase)[geographic_name] ||
        census_divisions.fetch(province_or_territory.downcase).fetch(geographic_name)

      geographic_code = if matches.size == 1
        matches[0][:id]
      else
        # Some boundary set's geographic name matches multiple identifiers:
        # * Shelburne (MD and T)
        # * Yarmouth (MD and T)
        # * Digby (MD and T)
        # * Lunenburg (MD and T)
        # * L'Ange Gardien (MÉ)
        match = matches.find{|match| %w(1201006 1202004 1203004 1206001 2482005).include?(match[:id])}
        if match
          match[:id]
        else
          matches = matches.select{|match| %w(C CY MD MÉ RCR T V TV).include?(match[:type])}
          if matches.size == 1
            matches[0][:id]
          else
            raise "#{geographic_name}: #{matches.inspect}"
          end
        end
      end

      items << [geographic_code, boundary_set]
    end

    type_re = / (borough|district|division|quartier|ward)s\z/

    puts CSV.generate_line(%w(id name))
    items.sort_by{|geographic_code,boundary_set|
      "#{geographic_code}-#{boundary_set["name"].match(type_re)[1]}"
    }.each do |geographic_code,boundary_set|
      ocd_type = boundary_set["name"].match(type_re)[1]

      JSON.load(open("https://represent.opennorth.ca#{boundary_set["related"]["boundaries_url"]}?limit=0"))["objects"].sort{|a,b|
        # Most identifiers are numbers, but some are "2A" or "2B".
        a = identifier(a)
        b = identifier(b)

        if a.class == b.class
          a <=> b
        elsif a.to_i == b.to_i
          a.to_s <=> b.to_s
        else
          a.to_i <=> b.to_i
        end
      }.each{|boundary|
        output("#{geographic_code.size == 4 ? "cd" : "csd"}:#{geographic_code}/#{ocd_type}:",
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

  # Asked Ontario:
  # 2014-02-20 JShiu@amo.on.ca "I believe we do not have a report that lists this type of information."
  # 2014-02-18 amcto@amcto.com "we do not maintain a list of council seats within each municipality"
  # 2014-02-18 mininfo.mah@ontario.ca "We regret to inform you that we cannot assist on this matter."
  # 2014-02-24 info@elections.on.ca "Elections Ontario does not have that information to provide."
  def posts_count
    puts CSV.generate_line(%w(id posts_count))

    # @see https://novascotia.ca/dma/government/elections.asp
    # The spreadsheet and roo gems open the Excel file too slowly.
    Tempfile.open("data.xls") do |f|
      f.binmode
      open("http://www.novascotia.ca/dma/pdf/mun-municipal-election-results-2008-2012.xls") do |data|
        f.write(data.read)
      end

      type = "RGM" # the first list is of regional municipalities
      Spreadsheet.open(f.path).worksheet(1).each do |row|
        case row[0]
        when "Amherst" # the first item in the list of towns
          type = "T"
        when "Annapolis" # the first item in the list of municipal districts and counties
          type = "MD"
        # @see http://www.statcan.gc.ca/eng/subjects/standard/sgc/2016/concordance-2011-2016
        when "Bridgetown", "Hantsport", "Springhill"
          next
        end

        if row[0] && row[1] && row[0].strip != "Voter Turnout"
          fingerprint = ["ns", type, CensusSubdivisionName.new(row[0]).normalize.remove_type("ns").fingerprint] * ":"
          identifier, _ = CensusSubdivisionNameTypeMatcher.identifier_and_name(fingerprint)
          unless identifier
            fingerprint = CensusDivisionNameMatcher.fingerprint("ns", row[0])
            identifier, _ = CensusDivisionNameMatcher.identifier_and_name(fingerprint)
          end

          if identifier
            output(nil, identifier, Integer(row[1].value))
          else
            raise fingerprint
          end
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
      "District" => "DM",
      "City" => "CY",
      "Village" => "VL",
      "Island Municipality" => "IM",
      "Town" => "T",
      "Township" => "DM",
      "Regional Municipality" => "RGM",
      "Mountain Resort Municipality" => "VL",
      "Resort Municipality" => "DM",
    }
    bc_type_corrections = {
      "Maple Ridge" => "City", # District
    }

    data = Hash.new(0)
    url = "http://www.election2014.civicinfo.bc.ca/2014/reports/report_adv_results.asp?excel=yes&etype=%27MAYOR%27,%20%27COUNCILLOR%27"
    CSV.parse(open(url), :headers => true) do |row|
      data[[row["Local Government"], row["Jurisdiction Type"]]] += 1
    end

    data.each do |(name,type),count|
      type = bc_type_corrections.fetch(name, type)

      fingerprint = ["bc", bc_type_map.fetch(type), CensusSubdivisionName.new(name).normalize.fingerprint] * ":"
      identifier, _ = CensusSubdivisionNameTypeMatcher.identifier_and_name(fingerprint)

      if identifier
        output(nil, identifier, count)
      else
        raise fingerprint
      end
    end
  end

  # Asked Ontario:
  # 2014-02-11 amo@amo.on.ca "After reviewing our election data we found that we
  # have not been tracking election results by wards so are unable to compile a
  # list of municipalities that have wards."
  # 2014-02-18 amcto@amcto.com "we are unable to provide individual responses
  # from municipalities as a means to respect the confidentiality of their
  # responses"
  # 2014-02-11 mininfo.mah@ontario.ca "We regret to inform you that we do not
  # have the information you requested."
  # 2014-02-24 info@elections.on.ca "Elections Ontario does not have that
  # information to provide."
  # 2014-03-17 ontario.municipal.board@ontario.ca "The Board does not have such
  # a list. The OMB is an adjudicative tribunal that deals with appeals and
  # applications."
  # @see http://www.e-laws.gov.on.ca/html/statutes/english/elaws_statutes_01m25_e.htm#BK238
  # @see http://m.mpac.ca/about/corporate_overview/department.asp
  # @see https://www.omb.gov.on.ca/stellent/groups/public/@abcs/@www/@omb/documents/webasset/ec082186.pdf
  #
  # Asked Manitoba:
  # 2014-04-09 mmaa@mymts.net "You would have to call the Municipal department."
  # 2014-04-11 amm@amm.mb.ca jgreen@amm.mb.ca "We do not have such information for each municipality."
  # 2014-04-14 election@elections.mb.ca MRobertson@elections.mb.ca "I'm sorry but Elections Manitoba does not have this type of information."
  # 2014-04-14 mgi@gov.mb.ca Linda.Baleja@gov.mb.ca "We do not compile this information."
  # 2014-04-30 MLInfo@gov.mb.ca "You might try "Elections Manitoba" at (204) 945-5635"
  # MB: "Contact your local municipal office to find out whether a ward by-law is in place in your municipality."
  # @see http://web5.gov.mb.ca/mfas/elections_faq.aspx#voters_q4
  # @see http://web2.gov.mb.ca/laws/statutes/ccsm/m225e.php#87
  #
  # Asked Saskatchewan for boundary files:
  # 2014-03-21 ask@isc.ca John.Leonard@isc.ca "As far as anything within the RM’s such as their division boundaries we don’t have them."
  # 2014-03-24 muninfo@gov.sk.ca "Government Relations doesn't have RM maps."
  def has_children
    subdivisions = Hash.new("N")

    url = "http://geonb.snb.ca/ArcGIS/rest/services/GeoNB_ENB_MunicipalWards/MapServer/0?f=json"
    JSON.load(open(url))["drawingInfo"]["renderer"]["uniqueValueInfos"].each do |feature|
      geographic_name = CensusSubdivisionName.new(feature["value"]).normalize

      matches = census_subdivisions.fetch("nb")[geographic_name]

      geographic_code = if matches.size == 1
        matches[0][:id]
      else
        matches = matches.select{|match| %w(C RCR TV).include?(match[:type])}
        if matches.size == 1
          matches[0][:id]
        else
          raise "#{geographic_name}: #{matches.inspect}"
        end
      end

      subdivisions["ocd-division/country:ca/csd:#{geographic_code}"] = "Y"
    end

    # @see https://novascotia.ca/dma/government/elections.asp
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
        when "Towns"
          type = "T"
        when "Municipalities"
          type = "MD"
        end

        # Process municipalities with districts. Skip the header row.
        if row[0] && row[1] && row[0].strip != "Municipality"
          # Skip to the next municipality.
          next if row[0] == name
          name = row[0]

          value = row[0].sub(" (County)", "")
          identifier = nil

          # Avoid matching the county to the town.
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

    qc_type_corrections = {
      "M"  => "MÉ",
      "P"  => "PE",
    }

    url = "http://www.electionsquebec.qc.ca/francais/municipal/carte-electorale/liste-des-municipalites-divisees-en-districts-electoraux.php?index=1"
    Nokogiri::HTML(open(url)).xpath("//div[@class='indente zone-contenu']/div[@class='boite-grise']").inner_html.split("<br>").each do |node|
      text = node.force_encoding('iso-8859-1').encode('utf-8').gsub(/<\/?strong>/, '').gsub('&#8212;', '—').strip

      name, type = text.match(/\A(.+), (.+)\z/)[1..2]
      type = qc_type_corrections.fetch(type, type)

      # Try first without the type, because the source may be incorrect.
      fingerprint = CensusSubdivisionNameMatcher.fingerprint("qc", name)
      identifier, _ = CensusSubdivisionNameMatcher.identifier_and_name(fingerprint)
      unless identifier
        fingerprint = ["qc", type, CensusSubdivisionName.new(name).normalize.fingerprint] * ":"
        identifier, _ = CensusSubdivisionNameTypeMatcher.identifier_and_name(fingerprint)
      end

      if identifier
        subdivisions[identifier] = "Y"
      elsif name == "L'Ange-Gardien" # two subdivisions match
        subdivisions["ocd-division/country:ca/csd:2482005"] = "Y"
      else
        raise fingerprint
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
      if block[/^Division [2-9][0-9]*:/]
        subdivisions[identifier] = "Y"
      end
    end

    # These may opt to adopt wards in the future (2014-02-10). Check manually.
    ab_cities_without_subdivisions = [
      "4801006", # Medicine Hat
      "4802012", # Lethbridge
      "4802034", # Brooks
      "4806017", # Chestermere
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
    # These two lists are a complete list of all cities ("CY", "SM") in Alberta.
    ab_cities_with_subdivisions = [
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
        # @see http://www.electionspei.ca/municipal/wards/
        # @see http://www.electionspei.ca/index.php?number=1046804&lang=E
        when "11"
          if [
            "1102075", # Charlottetown
            "1102085", # Cornwall
            "1102080", # Stratford
            "1103025", # Summerside
          ].include?(type_id)
            output(nil, identifier, "Y")
          else
            output(nil, identifier, "N")
          end
        when "12", "13", "24", "47"
          output(nil, identifier, subdivisions[identifier])
        # @see http://www.municipalaffairs.gov.ab.ca/am_types_of_municipalities_in_alberta.cfm
        when "48"
          value = case classification
          when "CY", "SM"
            if ab_cities_without_subdivisions.include?(type_id)
              "N"
            elsif ab_cities_with_subdivisions.include?(type_id)
              "Y"
            else
              raise "Couldn't determine subdivisions: #{type_id}"
            end
          when "MD"
            "Y"
          when "ID", "SA", "SV", "T", "VL"
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
        $stderr.puts "Unrecognized leader style of address:\n#{block.gsub(/^/, "  ")}"
      end

      if block[/^(Alderman|Councillor|Member):/]
        member = $1
      elsif block[/^Division \d+:/]
        member = "Councillor"
      elsif raise_if_error
        raise "Unrecognized member style of address:\n#{block.gsub(/^/, "  ")}"
      end

      puts "#{identifier},#{leader},#{member}"
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
    elsif boundary["external_id"][/\A\d+\z/]
      boundary["external_id"].to_i
    elsif boundary["external_id"][/\A[\d.]+\z/]
      boundary["external_id"].to_f
    else
      boundary["external_id"]
    end
  end

  def type_map(province_or_territory)
    {}.tap do |hash|
      hash["csd"] = {}
      # @see http://www.mah.gov.on.ca/Page1591.aspx Dysart et al
      hash["csd"]["United Townships"] = "MU"
      # @see http://www.mds.gov.sk.ca/apps/Pub/MDS/welcome.aspx Creighton, La Ronge
      hash["csd"]["Northern Town"] = "T"

      indexes = {}

      OpenCivicDataIdentifiers.read("country-ca/ca_provinces_and_territories").to_h.each_with_index do |(identifier,_),index|
        indexes[identifier.split(":")[-1]] = index + 2
      end

      {"cd" => [4, 0, -2], "csd" => [5, 1, -1]}.each do |type,(table,start_index,end_index)|
        hash[type] ||= {}
        url = "http://www12.statcan.gc.ca/census-recensement/2016/ref/dict/tab/t1_#{table}-eng.cfm"
        Nokogiri::HTML(open(url)).xpath("//tr[@class]")[start_index..end_index].each do |tr|
          code, name = tr.xpath("./th").text.split(/\p{Space}– /, 2)
          # Skip the single "TV" in Ontario to translate "Town" to "T" instead of "TV".
          unless tr.at_xpath("./td[#{indexes[province_or_territory]}]/span") || province_or_territory == "on" && code == "TV"
            hash[type][name.split(" / ", 2)[0].split.map(&:capitalize).join(" ")] = code
            hash[type][code] = code
          end
        end
      end
    end
  end

  def census_divisions
    @census_divisions ||= {}.tap do |hash|
      OpenCivicDataIdentifiers.read("country-ca/ca_census_divisions").each do |identifier,name,name_fr,classification,organization_name|
        type_id = identifier[/[^:]+\z/]
        key = CensusDivisionIdentifier.new(type_id).province_or_territory_type_id
        hash[key] ||= {}
        hash[key][name] ||= []
        hash[key][name] << {:id => type_id, :type => classification}
      end
    end
  end

  def census_subdivisions
    @census_subdivisions ||= {}.tap do |hash|
      OpenCivicDataIdentifiers.read("country-ca/ca_census_subdivisions").each do |identifier,name,name_fr,classification,organization_name|
        type_id = identifier[/[^:]+\z/]
        key = CensusSubdivisionIdentifier.new(type_id).province_or_territory_type_id
        hash[key] ||= {}
        hash[key][name] ||= []
        hash[key][name] << {:id => type_id, :type => classification}
      end
    end
  end

  def census_subdivisions_on
    blocks = {}

    on_type_map = type_map("on")

    Nokogiri::HTML(open("http://www.mah.gov.on.ca/Page1591.aspx").read).xpath("//table[1]//tr[position() > 1]").each do |row|
      text = row.xpath(".//td[1]").text.strip.normalize_space
      if row.xpath(".//td[2]").text.strip == "Lower Tier"
        corrections = {
          "Mississippi Mills, Municipality of" => ["Mississippi Mills", "Town"],
          "Haldimand County" => ["Haldimand County", "City"],
          "Norfolk County" => ["Norfolk County", "City"],
        }

        if corrections.key?(text)
          name, type_name = corrections[text]
        elsif text[","]
          name, type_name = text.match(/\A(.+), (.+) of\z/)[1..2]
        else
          name, type_name = text.match(/\A(.+) (Municipality)\z/)[1..2]
        end

        # Ontario has 3 "M" and 65 "MU".
        if name == "The Nation"
          type = "M"
        # Ontario has 3 "C" and 46 "CY".
        elsif name == "Clarence-Rockland"
          type = "C"
        else
          type = on_type_map["cd"][type_name] || on_type_map["csd"][type_name] || raise("Unrecognized type name: '#{type_name}' (#{text})")
        end

        fingerprint = ["on", type, CensusSubdivisionName.new(name).normalize.fingerprint] * ":"
        identifier, _ = CensusSubdivisionNameTypeMatcher.identifier_and_name(fingerprint)
        unless identifier
          raise fingerprint
        end

        census_division_fingerprint = CensusDivisionNameMatcher.fingerprint("on", row.xpath(".//td[3]").text.strip)
        census_division_identifier, _ = CensusDivisionNameMatcher.identifier_and_name(census_division_fingerprint)
        unless census_division_identifier
          raise census_division_fingerprint
        end

        blocks[identifier] = census_division_identifier
      end
    end

    blocks
  end

  def census_subdivisions_sk
    blocks = {}

    sk_type_map = type_map("sk")

    # Select "Entire Directory" and click "Generate PDF".
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
    column_divider_re = /(?<=  )\S/
    pages = []
    page = []
    text = []

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
        # Start a new page.
        page = []
      else
        page << line
      end
    end

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

    sk_type_corrections = {
      "GRAND COULEE" => "VL", # T
    }
    sk_non_census_subdivisions = [
      # @see https://en.wikipedia.org/wiki/Division_No._18,_Saskatchewan#Unincorporated_communities
      # @see https://en.wikipedia.org/wiki/Category:Division_No._18,_Unorganized,_Saskatchewan
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

    # Split the text into blocks, one per subdivision.
    text.join("\n").split(/\n\n\n+/).each do |block|
      line = block.strip.split("\n").first

      if line[/^(.+), (.+?)(?: of)?$/]
        name = $1
        type = $2
      elsif line[/^RM of (.+)$/]
        name = $1
        type = "RM"
      end

      next if ["Northern Hamlet", "Northern Settlement"].include?(type) && sk_non_census_subdivisions.include?(name)

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
        census_subdivision_type = sk_type_corrections.fetch(name, sk_type_map["csd"].fetch(type))
        fingerprint = ["sk", census_subdivision_type, CensusSubdivisionName.new(name).normalize.fingerprint] * ":"
        identifier, _ = CensusSubdivisionNameTypeMatcher.identifier_and_name(fingerprint)
      end

      if identifier
        blocks[identifier] = block
      else
        raise fingerprint
      end
    end

    blocks
  end
end

MunicipalSubdivision.new("ca_municipal_subdivisions.csv").run(ARGV)
