#!/usr/bin/env ruby
# Created 2019-03-15
# # By: Henrik Lowenberg
# # Property of HCL Inc.
# # Description: 
# # Migrate hosts from Satellite 5 to Satellite 6
# # in a series of steps
#
# # This file: sat526MigrationMain.rb
# # Function: this file works as a placeholder for all
#   subscripts
#
# Step 1: Get and sort file with hostnames into an array
# Step 2: Get host's ENC variables stored in AD into an array
# Step 3: Get host's activation keys from Satellite 5
# Step 4: Get host's Channel subscriptions from Satellite 5 
# Step 5: Get host´s network adapter settings from Satellite 5
# Step 6: Generate host yaml file for hostentry creation in Satellite 6
# Step 7: Create Contenthost entry in Satellite 6
# Step 8: Create system group in Satellite 5 & populate with hosts successfully created in Satellite 6
# Step 9: Run remote job script on Satellite 5 system group
#           Remote Job Script function: 
#           create new puppet.conf, 
#           subscription-manager unregister
#           remove RHN Classic settings
#           download katello certificates for Satellite 6 capsule
#           register host to capsule with correct activation-keys
#           run puppet agent
#           register result on server & remote location
#
# Step 10: (manual step) Go into system group, click on each host and delete them from Satellite 5.
#          Note! Only after manual verification of successful migration
#          Delete system group in Satellite 5

# Require: 
#
#require("./sat526MigrationGetHost_Enc.rb")
#require("./sat526MigrationGetHost_ActivationKeys.rb")
#require("./sat526MigrationGetHost_Channels.rb")
#require("./sat526MigrationGetHost_nics.rb")
#require("./sat526MigrationGenerateHostFile.rb")
#require("./sat526MigrationCreateContenthostEntry.rb")
#require("./sat526MigrationCreateSatellite5SystemGroup.rb")
#require("./sat526MigrationRunremotejobAgainstSatellite5SystemGroup.rb")

# Class Definitions: 
#   GetHostList Class: 
#     checks if hostlist file is supplied as an argument or exits script
#     sorts hosts in file into array
#     goes through each element in array and checks for short hostnames and figures out the
#     FQDN name and updates the element or exits script
#
# Method Definitions:
#   will be explained in each sub-script


class GetHostList
attr_reader :listFile

  def initialize(listFile)
    @listFile = listFile
  end

  def file2Array
    begin
      #initialize new array instance
      @hostnames = Array.new
      # Loop through file and put each line into array
      File.open(@listFile, 'r').each { |line| @hostnames << line } 
#      @hostnames.each { |myhostname| puts "element: " + myhostname }
    rescue
      puts "Failed to open #{@listFile}!"
      exit
    end
  end

  def processArray
    # Update array: truncate FQDN names to short hostnames
#    p @hostnames.inspect
    @hostnames.map! {|map| map.split('.')[0]}
#    p @hostnames.inspect
    puts
    puts
    # initialize new array instance
    @fqdn = Array.new
    # loop though the hostnames
    @hostnames.each do |hname|
      # Process global host file
#      puts "processing... #{hname}"
      File.open("hosts") do |f|
        # Get 1st line matching hostname from array & put it in fqdn array
        puts hname
        puts f.each_line.select { |line| line.match(/hname/)  }
        @fqdn << f.each_line.lazy.select { |line|  line.match(/#{hname}/) }.first(1)
        f.rewind
      end
    exit
    end
   
#    Process @fqdn array and remove non FQDN entries
    if @fqdn.any? 
      puts @fqdn.inspect
      puts
      puts "- - -"
      puts
      # Regex Sub-Expressions that should extract ONLY FQDN
      regex = /\\t\K([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{1,61}[a-zA-Z0-9])(\.([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9]))(\.([a-zA-Z]{3}))\g<1>*/
#      regex = /^(?!:\/\/)([a-zA-Z0-9]+\.)?[a-zA-Z0-9][a-zA-Z0-9-]+\.[a-zA-Z]{2,6}?$\g<1>*/
#      @fqdn.each { |el| puts el.to_s[regex] }
      # Update array elements: sort out FQDN names and set rest of elements to nil
      @fqdn.map! {|el| el.to_s[regex] } 
      # Save a copy of the array to use 4 outputting incorrect hostnames
      fqdn_orig = @fqdn.dup
#      @fqdn.each { |el| puts el}
#      p fqdn.inspect
      # trim the array to remove any nil values
      @fqdn.compact!
#      puts @fqdn.inspect
      # Compare no of short hostnames with no of FQDNs and take action if they dont match
      puts "fqdn.length: #{@fqdn.length}, @hostnames.length #{@hostnames.length}"
      if @fqdn.length != @hostnames.length
        puts "There are hosts in your list that cannot be found with their FQDN names in global hosts file!"
        fqdn_orig.each_with_index do |element,index|
#          puts "#{index}: #{element}"
          if element.nil?
            print "#{@hostnames[index]} is missing FQDN name\n"
          end
        end
      exit
      end
    else
      puts "Error, no FQDN names could be found in global hosts file!"
      puts "Please update global hosts file on jumphost with: ip hostname FQDN"
      exit
    end
  end #End def processArray

end # End of Class
##################

unless ARGV.empty?
  if ARGV.first.start_with?("-")
    case ARGV.shift  # shift takes the first argument and removes it from the array
    when '-h', '--help'
      puts
      puts "Usage: #{__FILE__} -f filename"
      puts "filename should be a text file comprized of hosts you want to migrate from Satellite 5 to Satellite 6"
      puts
      puts
      puts "
### Script leyout:
# Step 1: Get and sort file with hostnames into an array
# Step 2: Get host's ENC variables stored in AD into an array
# Step 3: Get host's activation keys from Satellite 5
# Step 4: Get host's Channel subscriptions from Satellite 5
# Step 5: Get host´s network adapter settings from Satellite 5
# Step 6: Generate host yaml file for hostentry creation in Satellite 6
# Step 7: Create Contenthost entry in Satellite 6
# Step 8: Create system group in Satellite 5 & populate with hosts successfully created in Satellite 6
# Step 9: Run remote job script on Satellite 5 system group
#           Remote Job Script function:
#           create new puppet.conf,
#           subscription-manager unregister
#           remove RHN Classic settings
#           download katello certificates for Satellite 6 capsule
#           register host to capsule with correct activation-keys
#           run puppet agent
#           register result on server & remote location
#
# Step 10: (manual step) Go into system group, click on each host and delete them from Satellite 5.
#          Note! Only after manual verification of successful migration
#          Delete system group in Satellite 5

"
      exit 0
    when '-v', '--version'
      puts "Current version: 1.0"
      exit 0
    when '-f', '--file'
      listFile = ARGV[0]
      #puts "you entered a filename: #{listFile}"
      # instantiate class
      c1 = GetHostList.new(listFile)
      # # Create an instance of the method file2Array
      c1.file2Array
      # # Create an instance of the method processArray
      c1.processArray
      exit 0
    end
  end
end

if ARGV.empty? || ARGV !~ /^-/
  puts
  puts "Usage:"
  puts " #{__FILE__} -h|--help"
  puts " #{__FILE__} --version"
  puts " #{__FILE__} -f|--file <filename>"
  puts
  exit 1
end









