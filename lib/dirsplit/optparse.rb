require 'optparse'
class Dirsplit
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
end
