# coding: utf-8

require "rubygems"
require "bundler/setup"

require "csv"
require "open-uri"
require "optparse"
require "ostruct"

require "dbf"
require "unicode_utils/downcase"
require "zip/zip"

# Outputs a CSV line with the OCD identifier and associated content.
#
# @param [String] fragment an identifier fragment
# @param [String] identifier the locally unique identifier
# @param [String] content the content to associate to the identifier
# @see https://github.com/opencivicdata/ocd-division-ids#id-format
def output(fragment, identifier, content)
  prefix = "ocd-division/country:ca/#{fragment}"
  identifier = identifier.to_s
  content = content.to_s

  # Convert double dashes.
  identifier.gsub!('--', '—')
  content.gsub!('--', '—')

  # Remove extra whitespace.
  identifier = identifier.to_s.gsub(/\p{Space}+/, " ").strip

  # "Uppercase characters should be converted to lowercase."
  identifier = UnicodeUtils.downcase(identifier)

  # "Spaces should be converted to underscores."
  identifier.gsub!(/\p{Space}/, "_")

  # "All invalid characters should be converted to tilde (~)."
  identifier.gsub!(/[^\p{Ll}\d._~-]/, "~")

  # "Leading zeros should be dropped unless doing so changes the meaning of the identifier."
  identifier.sub!(/\A0+/, "")

  puts CSV.generate_line([prefix + identifier, content.strip])
end

class Runner
  class << self
    attr_reader :csv_filename, :translatable
  end

  def initialize
    @commands = []

    add_command({
      :name        => "names",
      :description => "Prints a CSV of identifiers and canonical names",
      :directory   => "identifiers/country-ca",
    })

    add_command({
      :name        => "names-fr",
      :description => "Prints a CSV of identifiers and French names",
      :directory   => "mappings/country-ca-fr",
    }) if self.class.translatable
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
        banner << "  #{" " * padding}  #{opts.program_name} #{command.name} > #{command.directory}/#{self.class.csv_filename}\n"
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
      meth = command.gsub('-', '_').to_sym
      if respond_to?(meth)
        send(meth)
      else
        puts %(`#{command}` is not a #{opts.program_name} command. See `#{opts.program_name} --help` for a list of available commands.)
      end
    end
  end
end

class ShapefileParser
  attr_reader :url, :prefix, :mappings, :filter

  # @param [String] url the URL to the shapefile
  # @param [String] prefix the OCD division prefix
  # @param [Hash] mappings mappings from attribute names to column names
  # @option mappings [String] :identifier the column for the identifier
  # @option mappings [String] :content the column for the content
  # @option mappings [String] :default the column for the default content
  def initialize(url, prefix, mappings, filter=nil)
    @url = url
    @prefix = prefix
    @mappings = mappings
    @filter = filter || lambda {|record| true}
  end

  # Outputs identifiers in CSV format.
  def run
    Zip::ZipFile.open(open(url)) do |zipfile|
      entry = zipfile.entries.find{|entry| File.extname(entry.name) == ".dbf"}
      if entry
        DBF::Table.new(StringIO.new(zipfile.read(entry))).map do |record|
          ShapefileRecord.new(record, mappings)
        end.select do |record|
          filter.call(record)
        end.sort.each do |record|
          output(prefix, record.identifier, record.content)
        end
      else
        raise "DBF file not found!"
      end
    end
  end
end

class ShapefileRecord
  include Comparable

  attr_reader :mappings, :attributes

  # @param [DBF::Record] record a shapefile record
  # @param [Hash] mappings mappings from attribute names to column names
  def initialize(record, mappings)
    @record = record
    @mappings = mappings
    @attributes = record.attributes
  end

  # @param [ShapefileRecord] other a shapefile record
  # @return [Integer] whether the other record is less than, equal to, or
  #   greater than this record
  def <=>(other)
    sort_key <=> other.sort_key
  end

  # @return [String] the record's identifier, or the record's content if the
  #   column for the identifier is not given
  def identifier
    if mappings.key?(:identifier)
      @record.attributes.fetch(mappings[:identifier]).to_s # May be an integer
    else
      content
    end
  end

  # @return [String] the record's content, of the record's default content if
  #   the content is empty
  def content
    result = @record.attributes.fetch(mappings[:content])
    if result.empty?
      @record.attributes.fetch(mappings[:default])
    else
      result
    end
  end

  # @return [String] the key on which to sort the record, which is its content
  #   or its identifier if the column for the identifier is given
  def sort_key
    if mappings.key?(:sort_key)
      Integer(@record.attributes.fetch(mappings[:sort_key]))
    elsif mappings.key?(:identifier)
      Integer(identifier.to_s.sub(/\A0+/, "")) rescue identifier
    else
      content
    end
  end
end
