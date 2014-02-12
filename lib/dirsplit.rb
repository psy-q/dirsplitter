require 'logger'

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
    @logger = Logger.new(STDOUT)

    @recursive = false
    @source = @options[:source] if @options[:source]
    @destination = @options[:destination] if @options[:destination]
    @recursive = @options[:recursive] if @options[:recursive]
    self.validate_directories
    if @errors.count == 0
      @checks_passed = true
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
      @errors << "Destination directory does not exist or is not writable." unless validate_destination_path(@destination)
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

  def self.extract_initial(filename)
    File.basename(filename)[0]
  end

  def destination_path_for(filename)
    initial = self.class.extract_initial(filename)
    destination_path = File.join(@destination, initial)
  end

  def validate_destination_path(destination_path)
    if File.exist?(destination_path)
      if File.writable?(destination_path)
        return true
      else
        @logger.error "Destination directory #{destination_path} is not writable."
        return false
      end
    else
      @logger.error "Destination directory #{destination_path} does not exist."
      return false
    end
  end

  def extract_initials
    initials = []
    if @files and @files.count > 0
      initials = @files.map {|file|
        self.class.extract_initial(file)
      }.uniq
    end
  end

  def make_subdirectories(directories)
    successes = 0
    directories.each do |directory|
      begin
        if Dir.mkdir(File.join(@destination, directory))
          successes += 1
        end
      rescue Errno::EEXIST
        @logger.error "The directory #{File.join(@destination, directory)} already exists."
      end
    end
    return successes
  end

  def copy_files
    successes = 0
    make_subdirectories(extract_initials)
    @files.each do |file|
      destination_path = destination_path_for(file)
      if validate_destination_path(destination_path)
        begin
          FileUtils.copy(file, destination_path)
          successes += 1
        rescue Exception => e
          @logger.error("Failed to copy #{file} to #{destination_path}: Copy failed with #{e}.")
        end
      else
        @logger.error("Failed to copy #{file} to #{destination_path}: Destination path does not validate.")
      end
    end
    return successes
  end

end
