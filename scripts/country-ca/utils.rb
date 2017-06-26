# coding: utf-8

require "rubygems"
require "bundler/setup"

require "csv"
require "json"
require "open-uri"
require "optparse"
require "ostruct"
require "tempfile"

require "dbf"
require "faraday"
require "mechanize"
require "nokogiri"
require "spreadsheet"
require "unicode_utils/downcase"
require "unicode_utils/upcase"
require "zip"

class String
  def normalize_space
    gsub(/\p{Space}+/, " ")
  end
end

def census_division_type_names
  {}.tap do |hash|
    Nokogiri::HTML(open("http://www12.statcan.gc.ca/census-recensement/2016/ref/dict/tab/t1_4-eng.cfm")).xpath("//th[@headers]/text()").each do |node|
      code, name = node.text.split(" – ", 2)
      hash[code] = name.downcase
    end
  end
end

def census_subdivision_type_names
  {}.tap do |hash|
    Nokogiri::HTML(open("http://www12.statcan.gc.ca/census-recensement/2016/ref/dict/tab/t1_5-eng.cfm")).xpath("//th[@headers]/text()").each do |node|
      code, name = node.text.split(" – ", 2)  # non-breaking space
      hash[code] = name.downcase
    end
  end
end

# @param [String] identifier a locally unique identifier
def clean_identifier(identifier)
  # Avoid frozen strings.
  identifier = identifier.to_s.dup

  # Remove extra whitespace.
  identifier = identifier.normalize_space.strip

  # Convert double dash to m-dash.
  identifier.gsub!("--", "—")

  # "Uppercase characters should be converted to lowercase."
  identifier = UnicodeUtils.downcase(identifier)

  # "Spaces should be converted to underscores."
  identifier.gsub!(/\p{Space}/, "_")

  # "All invalid characters should be converted to tilde (~)."
  identifier.gsub!(/[^\p{Ll}\d._~-]/, "~")

  # "Leading zeros should be dropped unless doing so changes the meaning of the identifier."
  identifier.sub!(/\A0+/, "")

  identifier
end

# Outputs a CSV line with the OCD identifier and associated data.
#
# @param [String] fragment an identifier fragment
# @param [String] identifier a locally unique identifier
# @param [Array<String>] data the data to associate to the identifier
# @see https://github.com/opencivicdata/ocd-division-ids#id-format
def output(fragment, identifier, *data)
  if fragment
    prefix = "ocd-division/country:ca/#{fragment}"
    identifier = prefix + clean_identifier(identifier)
  end

  # Convert double dash to m-dash.
  data = data.map(&:to_s).map(&:strip).map{|content| content.gsub("--", "—")}
  puts CSV.generate_line([identifier] + data)
end

class Runner
  def initialize(filename)
    @commands = []

    add_command({
      :name        => "names",
      :description => "Prints a CSV of identifiers and canonical names",
      :output_path => "identifiers/country-ca/#{filename}",
    })
  end

  def add_command(attributes)
    @commands << OpenStruct.new(attributes)
  end

  # Returns the command-line option parser.
  #
  # @return [OptionParser] the command-line option parser
  def opts
    @opts ||= OptionParser.new do |opts|
      opts.program_name = File.basename($PROGRAM_NAME)

      padding = @commands.map(&:name).map(&:size).max

      banner = "Usage: #{opts.program_name} COMMAND\n\nCommands\n"

      @commands.each do |command|
        banner << "  #{command.name.ljust(padding)}  #{command.description}\n"
        banner << "  #{" " * padding}  #{opts.program_name} #{command.name} > #{command.output_path}\n"
      end

      opts.banner = banner

      opts.separator ""
      opts.separator "Options:"
      opts.on_tail("-h", "--help", "Display this screen") do
        puts opts
        exit
      end
    end
  end

  # Runs the command. Most often run from a command-line script as:
  #
  #     runner.run(ARGV)
  #
  # @param [Array] args command-line arguments
  def run(args)
    opts.parse!(args)

    command = args.shift
    if command.nil?
      puts opts
    else
      meth = command.gsub("-", "_").to_sym
      if respond_to?(meth)
        send(meth)
      else
        puts %(`#{command}` is not a #{opts.program_name} command. See `#{opts.program_name} --help` for a list of available commands.)
      end
    end
  end
end

class ShapefileParser
  # @param [String] url the URL to the shapefile
  # @param [String] prefix the OCD division prefix
  # @param [Hash] mappings mappings from attribute names to column names
  # @option mappings [String] :id the attribute for the identifier
  # @option mappings [String] :name the attribute for the canonical name
  # @option mappings [String] :name_fr the attribute for the French name
  # @option mappings [String] :identifier the attribute for an alternate identifier
  def initialize(url, prefix, mappings, filter=nil)
    @url = url
    @prefix = prefix
    @mappings = mappings
    @filter = filter || lambda {|record| true}
  end

  # Outputs identifiers in CSV format.
  def run(options = {})
    headers = %w(id)
    @mappings.keys.each do |mapping|
      unless [:id, :sort_as].include?(mapping)
        headers << mapping
      end
    end
    unless options[:write_headers] == false
      puts CSV.generate_line(headers)
    end

    Zip::File.open(open(@url)) do |zipfile|
      entry = zipfile.entries.find{|entry| File.extname(entry.name) == ".dbf"}
      if entry
        DBF::Table.new(StringIO.new(zipfile.read(entry))).select do |record|
          record
        end.map do |record|
          ShapefileRecord.new(record, @mappings)
        end.select(&@filter).sort.each do |record|
          output(@prefix, *headers.map{|header| record.send(header)})
        end
      else
        raise "DBF file not found!"
      end
    end
  end
end

class ShapefileRecord
  include Comparable

  # @return [Hash] the record's attributes
  attr_reader :attributes

  # @return [String] the record's identifier
  attr_reader :id

  # @return [String] the record's canonical name
  attr_reader :name

  # @return [String,Integer] the value on which to sort the record
  attr_reader :sort_as

  # @param [DBF::Record] record a shapefile record
  # @param [Hash] mappings mappings from shapefile attribute names to CSV column names
  def initialize(record, mappings)
    @attributes = record.attributes
    @mappings = mappings

    @name = case @mappings.fetch(:name)
    when Symbol, String
      @attributes.fetch(@mappings[:name])
    else
      @mappings[:name].call(record)
    end

    @id = if @mappings.key?(:id)
      id = case @mappings[:id]
      when Symbol, String
        @attributes.fetch(@mappings[:id])
      else
        @mappings[:id].call(record)
      end

      id = if id.to_i == @id
        id.to_i.to_s # eliminate float precision
      else
        id.to_s # may be an integer
      end
    else
      name
    end

    @sort_as = if @mappings.key?(:sort_as)
      @attributes.fetch(@mappings[:sort_as]).to_s # may be an integer
    elsif @mappings.key?(:id)
      id
    else
      name
    end

    integer = sort_as.sub(/\A0+/, "")
    if integer[/\A(\d+)-\d{4}\z/]
      integer = $1
    end

    @sort_as = Integer(integer) rescue sort_as
  end

  # @param [ShapefileRecord] other a shapefile record
  # @return [Integer] whether the other record is less than, equal to, or
  #   greater than this record
  def <=>(other)
    sort_as <=> other.sort_as
  end

  def method_missing(method, *args, &block)
    if @mappings.key?(method)
      case @mappings[method]
      when Symbol, String
        @attributes.fetch(@mappings.fetch(method))
      else
        @mappings[method].call(self)
      end
    else
      super
    end
  end
end
