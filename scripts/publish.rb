#!/usr/bin/env ruby
# This file streamlines the various build processes associated with
# the Codewriting project.

# From the root directory of your project:
# chmod 755 scripts/publish.rb
# scripts/publish.rb --help

# Require gems
require 'yaml'
require 'optparse'
require 'asciidoctor'
require 'asciidoctor-pdf'

# Set default instance variables
@build_action = 'all'
@liquidoc_config_def = 'book-cw/_configs/backmatter.yml'
@base_path = Dir.pwd
@assets_source_path = 'assets'
@images_source_path = @assets_source_path + '/images'
@scripts_path_def = 'scripts'
@input_file_def = 'index.adoc'
@attributes_file_def = '_data/asciidoctor.yml'
@data_file_def = '_data/changelog.yml'
@pdf_theme_file_def = 'theme/pdf-theme.yml'
@fonts_dir_def = 'theme/fonts'
@output_path_def = '_output'
@scripts_path = @base_path + '/' + @scripts_path_def
@attributes_file= @base_path + '/' + @attributes_file_def
@data_file = @base_path + '/' + @data_file_def
@pdf_theme_file = @base_path + '/' + @pdf_theme_file_def
@fonts_dir = @base_path + '/' + @fonts_dir_def
@input_file = @base_path + '/' + @input_file_def
@output_path = @base_path + '/' + @output_path_def
@assets_output_path = @output_path + '/assets'
@output_filename = 'index'
@doctype = 'article'
@jekyll = {
  'action' => 'serve',
  'settings' => {
    'destination' => '_output'
  }
}

# Gather attributes from a fixed attributes file
# Use _data/attributes.yml or designate as -f path/to/filename.yml
# One of the key reasons I built this script, to centralize control
# over attributes source, establish environments programmatically, etc
def get_attributes attributes_file

  unless attributes_file == ""
    if attributes_file
      if File.exists? (attributes_file)
        attributes = YAML.load_file(attributes_file)
        attributes = attributes['attributes']
        attributes
      else
        puts "Attributes file called but not found at #{attributes_file}."
      end
    end
  end

  attributes
end

# Set attributes for direct Asciidoctor operations
def set_attributes attrs
  attributes = { }
  attributes["basedir"] = @base_path
  attributes.merge!get_attributes(@attributes_file)
  attributes = '-a ' + attributes.map{|k,v| "#{k}='#{v}'"}.join(' -a ')
  attributes
end

# Set attributes for Asciidoctor operations via Jekyll
def set_attributes_jekyll

end

# ASSET PREPARATION OPERATIONS
# Build glossary and bibliography from flat-file data sources
# using a separate script
def build_liquidoc config_file
  if @verbose
    puts "Building back matter..."
    vrb = "--verbose"
  else
    vrb = ""
  end
  command = "bundle exec #{@base_path}/scripts/liquidoc.rb -c #{config_file} #{vrb}"
  system command
  if @verbose
    puts command
  end
end

# Move images for HTML operations
def move_assets src, dest
  if @verbose
    puts "Copying image assets..."
  end
  FileUtils.mkdir_p(dest) unless File.exists?(dest)
  FileUtils.cp_r(src, dest)
  if @verbose
    puts "Recursively copied: #{src} --> #{dest}"
  end
end

# BOOK BUILD OPERATIONS
# Eventually this will be configuration-based rather than defined
# each as its own method

def build_asciidoctor_html
  attributes = set_attributes(@attributes)
  move_assets(@assets_source_path, @output_path)
  command = "bundle exec asciidoctor -n -o #{@output_path}/#{@output_filename}.html #{@input_file} #{attributes} -a imagedir=assets/images #{@verbose_tag}"
  if @verbose
    puts "Building Asciidoctor HTML."
  end
  system command
  if @verbose
    puts command
  end
  puts "HTML edition built."
end

def build_asciidoctor_pdf
  attributes = set_attributes(@attributes)
  command = "bundle exec asciidoctor-pdf -o #{@output_path}/#{@output_filename}.pdf #{@input_file} #{attributes} -a pdf-style=#{@pdf_theme_file} -a pdf-fontsdir=#{@fonts_dir} #{@verbose_tag}"
  if @verbose
    puts "Building PDF....."
  end
  system command
  if @verbose
    puts command
  end
  puts "PDF edition built."
end

def build_jekyll
  command = "bundle exec jekyll serve  #{@verbose_tag}"
  system command
end

# The switchboard method
def build_the_docs action
  case action
  when 'html'
    build_asciidoctor_html
  when 'jekyll'
    build_jekyll
  when 'pdf'
    build_asciidoctor_pdf
  when 'all'
    build_asciidoctor_html
    build_asciidoctor_pdf
  else
    puts "No valid build action."
  end
end

# Define and parse command-line option/argument parameters
parser = OptionParser.new do|opts|
  opts.banner = "Usage: publish.rb [options]\nAll PATHs are relative to base directory."

  opts.on("-b STRING", "--build=STRING", "What to build? Options: html, pdf, all. Default: #{@build_action}" ) do |n|
    @build_action = n
  end

  opts.on("-c", "--liquidoc-config=PATH", "Configuration file, sets standardized source, outfile, and template arguments for --liquidoc-parse option.") do |n|
    @config_file = @base_path + '/' + n
  end

  opts.on("-d PATH", "--data=PATH", "Path to a YAML data file to load. Default: #{@data_file_def}" ) do |n|
    @data_file = n
  end

  opts.on("-f PATH", "--attributes-file=PATH", "For passing in a standard YAML AsciiDoc attributes file. Default: #{@attributes_file_def}\n can be combined with --attribute argument." ) do |n|
    @attributes_file = n
  end

  opts.on("-i PATH", "--input-file=PATH", "Input file to convert. Defaults: #{@input_file_def}" ) do |n|
    @input_file = n
  end

  opts.on("-l", "--liquidoc-parse", "Run LiquiDoc to preprocess data into new source files, optionally providing a configuration file path. Default configuration file will be used unless --liquidoc-config is invoked.") do |n|
    @build_liquidoc = n
  end

  opts.on("-o STRING", "--output-filname=STRING", "Output file base name (without file extension). Defaults to #{@output_filename}") do |n|
    @output_filename = n
  end

  opts.on("-t PATH", "--pdf-theme=PATH", "Path to the asciidoctor-pdf theme YAML file. Default: #{@pdf_theme_file_def}" ) do |n|
    @data_file = n
  end

  opts.on("--verbose", "Verbose output." ) do |n|
    @verbose = true
    @verbose_tag = "--verbose"
  end

  opts.on("-h", "--help", "Returns help.") do
    puts opts
    exit
  end

end

parser.parse!
if @build_liquidoc
  if @config_file
    config_file = @config_file
  else
    config_file = @liquidoc_config_def
  end
  build_liquidoc(config_file)
end
build_the_docs(@build_action)
