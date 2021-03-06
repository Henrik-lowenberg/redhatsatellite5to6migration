#!/usr/bin/env ruby
# # By: Henrik Lowenberg
# # Description: Migrate hosts from Satellite 5 to Satellite 6 in a series of steps

class HostFinder
  attr_reader :listFile

  def initialize(listFile)
    @listFile = listFile
    @search   = Array.new
    @found    = Array.new
    @results  = Array.new
  end

  def run
    file_to_array
    process_array
    print_results
  end

  private

  def file_to_array
    File.open(@listFile, 'r').each do |line|
      @search << line.split('.')[0].strip
    end
  end

  def process_array
    File.open("hosts").each_line do |line|
      @search.each do |search|
        (@found << search; @results << line) if line.match(/#{search}/)
      end
    end
  end

  def print_results
    if @results.any?

      puts "\n======= MATCHING =======\n"
      @found.each_with_index do |match, i|
        puts @found[i] + ": => " + @results[i]
      end

      puts "\n======= MISSING =======\n"
      puts @search - @found

    else
      puts "No FQDN names could be found in global hosts file."
      puts "Please update global hosts file on jumphost with: `ip hostname FQDN`"
    end
    puts "\n"
  end
end

unless ARGV.empty?
  if ARGV.first.start_with?("-")
    case ARGV.shift
    when '-f', '--file'
      HostFinder.new(ARGV[0]).run
    
    when '-h', '--help'
      puts "Usage: #{__FILE__} -f filename"
      puts "Filename should be a text file comprized of hosts you want to migrate from Satellite 5 to Satellite 6"
    
    when '-v', '--version'
      puts "HostMatcher 1.0.0"
      
    end
  end
else
  puts
  puts "Usage:"
  puts " #{__FILE__} -f|--file <filename>"
  puts " #{__FILE__} -h|--help"
  puts " #{__FILE__} --version"
end
