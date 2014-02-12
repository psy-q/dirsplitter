require 'spec_helper'
require 'dirsplit'

require 'pry'
describe Dirsplit do

  before(:each) do
    @data_dir = File.join(File.dirname(__FILE__), "data")
  end

  before(:all) do
    @data_dir = File.join(File.dirname(__FILE__), "data")
    unless File.exist?(File.join(@data_dir, "destination"))
      Dir.mkdir(File.join(@data_dir, "destination"))
    end
    unless File.exist?(File.join(@data_dir, "empty_source"))
      Dir.mkdir(File.join(@data_dir, "empty_source"))
    end
  end

  after(:all) do
    path = File.join(@data_dir, "destination", "**", "*")
    FileUtils.rm_rf(Dir.glob(path))
  end

  it "should complain if the source directory isn't set" do
    ds = Dirsplit.new(:source => nil, :destination => File.join(@data_dir, "destination"))
    ds.validate_directories
    ds.errors.include?("Source directory is required.").should == true
    ds.checks_passed.should == false
  end

  it "should complain if the destination directory is not writable or non-existant"  do
    ds = Dirsplit.new(:source => File.join(@data_dir, "empty_source"), :destination => File.join(@data_dir, "unwritable_destination"))
    ds.validate_directories
    ds.errors.include?("Destination directory does not exist or is not writable.").should == true
    ds.checks_passed.should == false
  end

  it "should complain if the source and destination directories are the same"  do
    ds = Dirsplit.new(:source => File.join(@data_dir, "empty_source"), :destination => File.join(@data_dir, "empty_source"))
    ds.validate_directories
    ds.errors.include?("Source and destination cannot be the same directory.").should == true
    ds.checks_passed.should == false
  end

  context "when used non-recursively" do
    it "should gather all files only from the source directory itself" do
      ds = Dirsplit.new(:source => File.join(@data_dir, "source_with_100_files"), :destination => File.join(@data_dir, "destination"))
      ds.recursive.should == false
      ds.gather_files.count.should == 97
    end
  end

  context "when used recursively" do
    it "should gather all files from the source directory and all its subdirs" do
      ds = Dirsplit.new(:source => File.join(@data_dir, "source_with_100_files"), :destination => File.join(@data_dir, "destination"))
      ds.recursive = true
      ds.gather_files.count.should == 100
    end
  end

  # Alphabetic mode is the only one we have right now.
  context "in alphabetic mode" do
    it "should suggest directory names for creation based on the first character of each file encountered" do
      ds = Dirsplit.new(:source => File.join(@data_dir, "source_with_alphabetic_files"), :destination => File.join(@data_dir, "destination"))
      ds.gather_files
      ds.extract_initials.sort.should == %w(a b c d e)
    end

    it "should copy files from the source directory to destination directories matching the initial of the filenames" do
      ds = Dirsplit.new(:source => File.join(@data_dir, "source_with_alphabetic_files"), :destination => File.join(@data_dir, "destination"))
      ds.gather_files
      ds.copy_files.should == 5
      fullpaths = [
        File.join(@data_dir, "destination", "a", "aardvark"),
        File.join(@data_dir, "destination", "b", "banana"),
        File.join(@data_dir, "destination", "c", "calice"),
        File.join(@data_dir, "destination", "d", "dromedary"),
        File.join(@data_dir, "destination", "e", "eratosthenes")
      ]
      fullpaths.each do |fullpath|
        File.exists?(fullpath).should == true
      end
    end

    it "should make directories underneath the destination directory" do
      directories = ["a","b","c"]
      fullpaths = []
      ds = Dirsplit.new(:source => File.join(@data_dir, "empty_source"), :destination => File.join(@data_dir, "destination"))
      ds.make_subdirectories(directories).should == 3
      directories.each do |dir|
        fullpaths << File.join(@data_dir, "destination", dir)
      end
      fullpaths.each do |fullpath|
        File.exists?(fullpath).should == true
      end
    end

    it "should accept arrays of file paths, not just strings, to make subdirectories with" do
      directories = [
        File.join("a", "a"),
        File.join("b", "b"),
        File.join("c", "c")
      ]
      fullpaths = []
      ds = Dirsplit.new(:source => File.join(@data_dir, "empty_source"), :destination => File.join(@data_dir, "destination"))
      ds.make_subdirectories(directories).should == 3
      directories.each do |dir|
        fullpaths << File.join(@data_dir, "destination", dir)
      end
      fullpaths.each do |fullpath|
        File.exists?(fullpath).should == true
      end
    end

    it "should copy only up to the specified limit of files per directory" do
      counting_destination = File.join(@data_dir, "destination", "for_counting")
      Dir.mkdir(counting_destination)
      ds = Dirsplit.new(:source => File.join(@data_dir, "source_with_100_files"), :destination => counting_destination)
      ds.recursive = true
      ds.limit = 20
      ds.gather_files
      ds.copy_files

      (1..9).each do |i|
        path = File.join(counting_destination, i.to_s, "**", "*")
        files = Dir.glob(path).reject {|file| File.directory?(file) }
        files.count.should_not == 0
        files.count.should <= 20
      end
    end

    it "should determine which and how many subdirectories to create so as to not exceed the file limit per dir" do
      ds = Dirsplit.new(:source => File.join(@data_dir, "source_with_many_files_per_initial"), :destination => File.join(@data_dir, "destination"))
      ds.recursive = true
      ds.limit = 2
      ds.gather_files
      subdirectories = ds.determine_subdirectories
      subdirectories.count.should == 10
      subdirectories.include?("a/3").should == true
    end

    it "should copy files to numbered subdirectories if they would exceed the file number limit otherwise" do
      counting_destination = File.join(@data_dir, "destination", "for_counting_alpha")
      Dir.mkdir(counting_destination)
      ds = Dirsplit.new(:source => File.join(@data_dir, "source_with_many_files_per_initial"), :destination => counting_destination)
      ds.recursive = true
      ds.limit = 2
      ds.gather_files
      ds.copy_files

      File.exist?(File.join(counting_destination, "a", "1", "aardvark")).should == true
      File.exist?(File.join(counting_destination, "a", "3", "abroad")).should == true
      File.exist?(File.join(counting_destination, "a", "7", "adrenalin")).should == true

    end


  end



end
