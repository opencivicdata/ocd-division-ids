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

  puts CSV.generate_line([prefix + identifier, content])
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
  attr_reader :url, :prefix, :mappings

  # @param [String] url the URL to the shapefile
  # @param [String] prefix the OCD division prefix
  # @param [Hash] mappings mappings from attribute names to column names
  # @option mappings [String] :identifier the column for the identifier
  # @option mappings [String] :name the column for the division name
  # @option mappings [String] :default the column for the default division name
  def initialize(url, prefix, mappings)
    @url = url
    @prefix = prefix
    @mappings = mappings
  end

  # Outputs identifiers in CSV format.
  def run
    Zip::ZipFile.open(open(url)) do |zipfile|
      entry = zipfile.entries.find{|entry| File.extname(entry.name) == ".dbf"}
      if entry
        DBF::Table.new(StringIO.new(zipfile.read(entry))).map do |record|
          ShapefileRecord.new(record, mappings)
        end.sort.each do |record|
          output(prefix, record.identifier, record.name)
        end
      else
        raise "DBF file not found!"
      end
    end
  end
end

class ShapefileRecord
  include Comparable

  attr_reader :record, :mappings

  # @param [DBF::Record]
  # @param [Hash] mappings mappings from attribute names to column names
  def initialize(record, mappings)
    @record = record
    @mappings = mappings
  end

  def <=>(other)
    sort_key <=> other.sort_key
  end

  def [](key)
    record.attributes.fetch(mappings[key])
  end

  def key?(key)
    record.attributes.key?(mappings[key])
  end

  def identifier
    if mappings.key?(:identifier)
      self[:identifier]
    else
      name
    end
  end

  def name
    result = self[:name]
    if result.empty?
      self[:default]
    else
      result
    end
  end

  def sort_key
    if mappings.key?(:identifier)
      Integer(identifier_without_leading_zeros) rescue self[:identifier]
    else
      name
    end
  end

private

  def identifier_without_leading_zeros
    self[:identifier].to_s.sub(/\A0+/, "")
  end
end
