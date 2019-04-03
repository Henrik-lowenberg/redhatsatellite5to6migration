#!/usr/bin/env ruby
# Created 2019-03-30
# # By: Henrik Lowenberg
# # Property of HCL Inc.
# # Description:
# # Get hosts' ENC variables
#
# # This file: sat526MigrationGetHost_Enc.rb

=begin
Format of json data:
1dyfqn2:
  parameters:
    base: ubuntu01
    customer: volvo
    devicetype: ws
    site: got
    supportlevel: basic
    sz: vcn
    uuma: got
=end
require 'yaml'

puts " #{__FILE__} running..."

dumpfile =YAML.load_file('/data01/puppet/enc/combined.yaml')
#dumpfile =YAML.load_file('combined.yaml')

#p dumpfile.class
#p dumpfile.inspect
#puts dumpfile.keys

#host_enc = Hash.new
host_enc = Array.new
#p $hosts.class
$hosts.each do |host|
  host_enc << host
  host_enc << dumpfile[host]['parameters']
  #puts dumpfile[host]['parameters']
end
#p host_enc.inspect
