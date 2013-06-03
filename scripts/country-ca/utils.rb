require "rubygems"
require "bundler/setup"

require "csv"
require "open-uri"
require "optparse"

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
