#!/usr/bin/env ruby

require 'optparse'

class Dirsplit
  attr_accessor :options
  attr_accessor :source
  attr_accessor :destination
  attr_accessor :recursive
  attr_reader :errors
  attr_reader :checks_passed
  attr_reader :files


  def initialize(options = {})
    @options ||= options
    @errors = []
    @checks_passed = false

    @recursive = false
    self.parse_options
    @source = @options[:source] if @options[:source]
    @destination = @options[:destination] if @options[:destination]
    @recursive = @options[:recursive] if @options[:recursive]
    self.validate_directories
    if @errors.count == 0
      @checks_passed = true
    end
  end

  def parse_options
    begin
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: dirsplit [options] -s SOURCE -d DESTINATION"

        # Currently alphabetic mode is the only one that's supported
        @options[:mode] = :alpha
        opts.on("-m [MODE]", "--mode [MODE]", [:alpha], "Kind of subdirectories to create.") do |m|
          @options[:mode] = m
        end

        opts.on "-s SOURCE", "--source SOURCE", "Source directory to copy files from." do |s|
          @options[:source] = s
        end

        opts.on "-d DESTINATION", "--destination DESTINATION", "Destination directory to create subdirs in." do |d|
          @options[:destination] = d
        end

        opts.on "-r", "--recursive", "Work recursively." do |r|
          @options[:recursive] = r
        end

        opts.on_tail("-h", "--help", "Show this help.") do
          puts opts
          exit
        end
      end.parse!
    rescue Exception => e
      puts "Error parsing arguments: #{e}"
    end
  end

  def validate_directories
    if @source.nil?
      @errors << "Source directory is required."
    else
      @errors << "Source directory not readable." unless File.stat(@source).readable?
    end
    if @destination.nil?
      @errors << "Destination directory is required." if @destination.nil?
    else
      @errors << "Destination directory not readable." unless File.stat(@destination).readable?
      @errors << "Destination directory not writable." unless File.stat(@destination).writable?
    end

    unless @source.nil? and @destination.nil?
      @errors << "Source and destination cannot be the same directory." if @source == @destination
    end
  end

  def gather_files
    if @recursive
      path = File.join(@source, "**", "*")
    else
      path = File.join(@source, "*")
    end
    @files = Dir.glob(path).reject {|file| File.directory?(file) }
  end

  def unique_initials
    initials = []
    if @files and @files.count > 0
      initials = @files.map {|file|
        File.basename(file)[0]
      }.uniq
    end
  end

end
