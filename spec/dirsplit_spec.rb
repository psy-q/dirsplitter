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

end
