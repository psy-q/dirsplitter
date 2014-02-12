require 'optparse'
class Dirsplit
  def parse_options(args)
    begin
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: dirsplit [options] -s SOURCE -d DESTINATION"

        opts.on "-s SOURCE", "--source SOURCE", String, "Source directory to copy files from." do |s|
          @source = s
        end

        opts.on "-d DESTINATION", "--destination DESTINATION", String, "Destination directory to create subdirs in." do |d|
          @destination = d
        end

        @recursive = false
        opts.on "-r", "--recursive", "Work recursively." do |r|
          @recursive = r
        end

        opts.on "-l", "--limit", Integer, "Maximum number of files per destination directory." do |l|
          @limit = l
        end

        opts.on_tail("-h", "--help", "Show this help.") do
          puts opts
        end
      end.parse(args)
    rescue Exception => e
      puts "Error parsing arguments: #{e}"
    end
  end
end
