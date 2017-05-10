#!/usr/bin/env ruby
require 'yaml'
require 'optparse'
require 'liquid'

# set defaults to sample files
@base_path = File.expand_path(File.dirname(__FILE__))+ '/../'
@template_file = @base_path + '/_templates'
@data_path = @base_path + '/_data'
@output_path = @base_path + '/_output'
@config_file = @base_path + '/configs/cfg-sample.yml'
@verbose = false
# needs more verbosity in build operations

# Adapted from Nikhil Gupta
# http://nikhgupta.com/code/wrapping-long-lines-in-ruby-for-display-in-source-files/
class String

  def wrap options = {}
    width = options.fetch(:width, 76)
    commentchar = options.fetch(:commentchar, '')
    self.strip.split("\n").collect do |line|
      line.length > width ? line.gsub(/(.{1,#{width}})(\s+|$)/, "\\1\n#{commentchar}") : line
    end.map(&:strip).join("\n#{commentchar}")
  end

  def indent options = {}
    spaces = " " * options.fetch(:spaces, 4)
    self.gsub(/^/, spaces).gsub(/^\s*$/, '')
  end

  def indent_with_wrap options = {}
    spaces = options.fetch(:spaces, 4)
    width  = options.fetch(:width, 80)
    width  = width > spaces ? width - spaces : 1
    self.wrap(width: width).indent(spaces: spaces)
  end

  # from Jekyll's Liquid plugin (find another way to call?)
  def slugify options = {}
    unless self.nil?
      self \
        # Replace each non-alphanumeric character sequence with a hyphen
        .gsub(/[^a-z0-9]+/i, '-') \
        # Remove leading/trailing hyphen
        .gsub(/^\-|\-$/i, '') \
        # Downcase it
        .downcase
    end
  end
end

# Liquid modules for text manipulation
module Liquidoxify
  def plainwrap input
    input.wrap
  end
  def commentwrap input
    input.wrap commentchar: "# "
  end
  def unwrap input # Not fully functional; inserts explicit '\n'
    if input
      token = "[g59hj1k]"
      input.gsub(/\n\n/, token).gsub(/\n/, ' ').gsub(token, "\n\n")
    end
  end
  def slugify input
    input.slugify
  end
end

Liquid::Template.register_filter(Liquidoxify)

# Pull in a semi-structured data file
def get_data data_file
  YAML.load_file(data_file)
end

# Establish source, template, and output files for build jobs from a config file
def config_build config_file
  config = get_data(config_file)
  if config['test']
    puts config['test']
  end
  for src in config['sources']
    data = @base_path + '/' + src['data']
    for cfgn in src['builds']
      template = @base_path + '/' + cfgn['template']
      output = @base_path + '/' + cfgn['output']
      liquify(template, data, output)
    end
  end
end

# Parse data_file using template_file, saving to out_file
def liquify template_file, data_file, out_file
  template = File.read(template_file) # reads the template file
  template = Liquid::Template.parse(template) # compiles template
  data = get_data(data_file) # gathers the data
  # makes the output dir if it doesn't exist
  Dir.mkdir(@output_path) unless File.exists?(@output_path)
  output = template.render(data, { strict_filters: true }) # renders the output
  if template.errors[0]
    puts "Errors: #{template.errors}"
  end
  File.open(out_file, 'w') { |file| file.write(output) } # saves file
  if File.exists?(out_file)
    if @verbose
      puts "File built: #{out_file}"
    end
  end
end

# Define command-line option/argument parameters
# From the root directory of your project:
# $ ./parse.rb --help
parser = OptionParser.new do|opts|
  opts.banner = "Usage: ./liquidoxify.rb [options]"

  opts.on("-b PATH", "--base=PATH", "The base directory, relative to this script. Defaults to /../ ." ) do |n|
    @data_file = @base_path + '/' + n
  end

  opts.on("-c", "--configuration=PATH", "Configuration file, sets standardized data, outfile, and template arguments.") do |n|
    @config_file = @base_path + '/' + n
  end

  opts.on("-d PATH", "--data=PATH", "Semi-structured data source (input) path. Ex. path/to/data.yml. Required unless --configuration is called." ) do |n|
    @data_file = @base_path + '/' + n
  end

  opts.on("-o PATH", "--output=PATH", "Output file path for generated content. Ex. path/to/file.adoc. Required unless --configuration is called.") do |n|
    @output_file = @base_path + '/' + n
  end

  opts.on("-t PATH", "--template=PATH", "Path to liquid template. Required unless --configuration is called." ) do |n|
    @template_file = @base_path + '/' + n
  end

  opts.on("--verbose", "Verbose output." ) do |n|
    @verbose = true
  end

	opts.on("--help", "Returns help.") do
		puts opts
		exit
	end
end

# Pars options.
parser.parse!

# Parse data into docs!
# liquify() takes the names of a Liquid template, a data file, and an output doc.
# Input and output file extensions are non-determinant; your template
# file establishes the structure.

if @data_file
  liquify(@template_file, @data_file, @output_file)
else
  config_build(@config_file)
end
