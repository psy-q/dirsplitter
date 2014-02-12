require 'logger'

class Dirsplit
  attr_accessor :options
  attr_accessor :source
  attr_accessor :destination
  attr_accessor :recursive
  attr_accessor :limit
  attr_reader :errors
  attr_reader :checks_passed
  attr_reader :files

  def initialize(options = {})
    @options ||= options
    @errors = []
    @checks_passed = false
    @logger = Logger.new(STDOUT)
    @limit = nil

    @recursive = false
    @source = @options[:source] if @options[:source]
    @destination = @options[:destination] if @options[:destination]
    @recursive = @options[:recursive] if @options[:recursive]
    @limit = @options[:limit].to_i if @options[:limit]
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

  def extract_initial(filename)
    File.basename(filename)[0]
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
        extract_initial(file)
      }.uniq
    end
  end

  def files_and_destinations
    initials = {}
    files_and_destinations = []
    if @files and @files.count > 0
      @files.each do |file|
        initials[extract_initial(file).to_sym] ||= []
        initials[extract_initial(file).to_sym] << file
      end

      initials.each_pair do |initial, files|
        # Yes, this means if two files in source have the same name, only the first one will be written
        # to destination when in recursive mode.
        files.sort! { |a,b| File.basename(a) <=> File.basename(b) }.uniq
        if @limit and files.count > @limit
          filecount = 0
          subdir = 1
          files.each do |file|
            if filecount == @limit
              subdir += 1
              filecount = 0
            end
            files_and_destinations << [file, File.join(initial.to_s, subdir.to_s)]
            filecount += 1
          end
        else
          files.each do |file|
            files_and_destinations << [file, initial.to_s]
          end
        end
      end
    end
    files_and_destinations
  end


  def determine_subdirectories
    subdirs = []
    files_and_destinations.each do |fd|
      subdirs << fd[1]
    end
    subdirs.uniq
  end

  def make_subdirectories(directories)
    successes = 0
    directories.each do |directory|
      begin
        FileUtils.mkdir_p(File.join(@destination, directory))
        successes += 1
      rescue Exception => e
        @logger.info "The directory #{File.join(@destination, directory)} could not be created: #{e}."
      end
    end
    return successes
  end

  def copy_files
    successes = 0
    make_subdirectories(determine_subdirectories)
    files_and_destinations.each do |fd|
      file_source = fd[0]
      file_destination = File.join(@destination, fd[1])
      if validate_destination_path(file_destination)
        begin
          FileUtils.copy(file_source, file_destination)
          successes += 1
        rescue Exception => e
          @logger.error("Failed to copy #{file_source} to #{file_destination}: Copy failed with #{e}.")
        end
      else
        @logger.error("Failed to copy #{file_source} to #{file_destination}: Destination path does not validate.")
      end
    end
    return successes
  end


end
