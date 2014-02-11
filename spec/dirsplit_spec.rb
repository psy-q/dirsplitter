require 'spec_helper'
require 'dirsplit'

require 'pry'
describe Dirsplit do

  before do
    @data_dir = File.join(File.dirname(__FILE__), "data")
  end

  it "should complain if the source directory isn't set" do
    ds = Dirsplit.new(:source => nil, :destination => File.join(@data_dir, "destination"))
    ds.validate_directories
    ds.errors.include?("Source directory is required.").should == true
    ds.checks_passed.should == false
  end

  it "should complain if the destination directory is not writable"  do
    ds = Dirsplit.new(:source => File.join(@data_dir, "empty_source"), :destination => File.join(@data_dir, "unwritable_destination"))
    ds.validate_directories
    ds.errors.include?("Destination directory not writable.").should == true
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

  context "in alphabetic mode" do
    it "should suggest directory names for creation based on the first character of each file encountered" do
      ds = Dirsplit.new(:source => File.join(@data_dir, "source_with_alphabetic_files"), :destination => File.join(@data_dir, "destination"))
      ds.gather_files
      ds.unique_initials.sort.should == %w(a b c d e)
    end

  end

end
