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
#           RHN Classic to RHSM
#             Install package: subscription-manager subscription-manager-migration subscription-manager-migration-data
#             Run script rhn-migrate-classic-to-rhsm
#              *maybe with rhn-migrate-classic-to-rhsm --serverurl=rhnsat.srv.volvo.com (login required)
#             Verify with oo-admin-yum-validator 
#           create new puppet.conf,
#           subscription-manager unregister
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
    @hosts_search   = Array.new
    @hosts_found    = Array.new
    @hosts_results  = Array.new
    @hosts_fqdn = Array.new
  end

 def run
    file_to_array
    process_array
    #print_results
    #initiate_steps
  end

  private

  def file_to_array
    begin
      # Loop through file and put each line into array
      File.open(@listFile, 'r').each do |line|
        @hosts_search << line.split('.')[0].strip
      end
    rescue
      puts "Failed to open #{@listFile}!"
      exit 2
    end
  end

  def process_array
    File.open("/etc/hosts").each_line do |line|
      @hosts_search.each do |search|
        (@hosts_found << @hosts_search; @hosts_results << line) if line.match(/#{search}/)
      end
    end
    puts "@hosts_results b4 regex " ; p @hosts_results.inspect
#    puts "@hosts_found " ; p @hosts_found.inspect
    #puts 
    @hosts_results_dup = @hosts_results
#    Testing which regular expression matches FQDN
#    regex = /\(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{1,61}[a-zA-Z0-9])(\.([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9]))(\.([a-zA-Z]{3}))\g<1>*/
    #regex = /([a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix)\g<1>*/
#    regex = /([a-zA-Z]|[a-zA-Z0-9][a-zA-Z0-9\-]{1,61}[a-zA-Z0-9])(\.([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9]))(\.([a-zA-Z]{3}))/ 
#    regex = /([a-zA-Z][a-zA-Z0-9][a-zA-Z0-9\-]{1,62})\.([a-zA-Z]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,62})\.[a-zA-Z]{3,}/
    regex = /([a-zA-Z][a-zA-Z0-9\-]{1,61})(\.([a-zA-Z]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}))+(\.([a-zA-Z]{2,}))/
    # print matches
    craparray = Array.new
    @hosts_results.each { |line| (craparray << line[regex] ) if line.match(/#{regex}/) }
    puts "-------------------------------------"
    #@hosts_results.each { |line| puts line[regex] }
    puts
    craparray.each {|element| puts element}
    puts puts puts
    puts "-------------------------------------"

#    craparray.each { |fqdnline| puts fqdnline }
    exit
    # update the array to only match the regular expression
    #@hosts_results.map! {|el| el.to_s[regex] }
    #@hosts_results.compact!
    puts "@hosts_results after regex " ; p @hosts_results.inspect
  end #End def processArray

  def print_results
    #system "clear"
    puts "hosts_search contains " + @hosts_search.length.to_s + " elements"
    puts "hosts_results contains " + @hosts_results.length.to_s + " elements"
    puts "@hosts_found contains " + @hosts_found.length.to_s + " elements"
 
    puts "@hosts_search  " ; p @hosts_search.inspect
    puts "@hosts_results " ; p @hosts_results.inspect
    puts "@hosts_found " ; p @hosts_found.inspect
exit
    if @hosts_results.any?
      if @hosts_search.length != @hosts_results.length
        puts "There are hosts in your list that cannot be found with their FQDN names in global hosts file!"
          @hosts_results_dup.each_with_index do |element,index|
            #puts "#{index}: #{element}"
            if element.nil?
              print "#{@hosts_search[index]} is missing FQDN name\n"
            end
          end
      exit 3
      end
    else
      puts "Error, no FQDN names could be found in global hosts file!"
      puts "Please update global hosts file on jumphost with: ip hostname FQDN"
      exit 4
    end
  end #End def print_results
 
  def initiate_steps
    #require("./sat526MigrationGetHost_Enc.rb")
    #require("./sat526MigrationGetHost_ActivationKeys.rb")
    #require("./sat526MigrationGetHost_Channels.rb")
    #require("./sat526MigrationGetHost_nics.rb")
    #require("./sat526MigrationGenerateHostFile.rb")
    #require("./sat526MigrationCreateContenthostEntry.rb")
    #require("./sat526MigrationCreateSatellite5SystemGroup.rb")
    #require("./sat526MigrationRunremotejobAgainstSatellite5SystemGroup.rb")
  end

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
### Script layout:
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
    when '-v', '--version'
      puts "Satellite Host Migration Tool version: 1.0"
    when '-f', '--file'
      GetHostList.new(ARGV[0]).run
    end
  end
else
  puts
  puts "Usage:"
  puts " #{__FILE__} -h|--help"
  puts " #{__FILE__} --version"
  puts " #{__FILE__} -f|--file <filename>"
end
