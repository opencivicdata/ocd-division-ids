require "rubygems"
require "bundler/setup"

require "csv"
require "open-uri"
require "optparse"

require "active_support/core_ext/string/inflections"
require "dbf"
require "zip/zip"

class Runner
  class << self
    attr_reader :csv_filename, :translatable
  end

  # Returns the command-line option parser.
  #
  # @return [OptionParser] the command-line option parser
  def opts
    @opts ||= OptionParser.new do |opts|
      opts.program_name = File.basename($PROGRAM_NAME)

      banner = <<-EOS
Usage: #{opts.program_name} COMMAND

Commands:
  identifiers   Prints a CSV of identifiers and English names, e.g.:
                #{opts.program_name} identifiers > identifiers/country-ca/#{self.class.csv_filename}
      EOS

      if self.class.translatable
        banner << <<-EOS
  translations  Prints a CSV of identifiers and French names, e.g.:
                #{opts.program_name} translations > mappings/country-ca-fr/#{self.class.csv_filename}
        EOS
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
    elsif respond_to?(command.to_sym)
      send(command.to_sym)
    else
      puts %(`#{command}` is not a #{opts.program_name} command. See `#{opts.program_name} --help` for a list of available commands.)
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
        puts CSV.generate{|csv|
          DBF::Table.new(StringIO.new(zipfile.read(entry))).map do |record|
            ShapefileRecord.new(record, mappings)
          end.sort.each do |record|
            csv << [
              "#{prefix}#{record.identifier}",
              record.name,
            ]
          end
        }
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

  def identifier
    if mappings.key?(:identifier)
      self[:identifier].to_s.downcase
    else
      name.parameterize
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
      Integer(self[:identifier]) rescue self[:identifier]
    else
      name
    end
  end
end
