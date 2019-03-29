#!/usr/bin/env ruby
# Created 2019-03-15
# # By: Henrik Lowenberg
# # Property of HCL Inc.
# # Description:
# # Gather ENC variables for hosts
#
# # This file: sat526MigrationGetHost_Enc.rb

=begin
Format of binary file data:

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

puts " #{__FILE__} running..."
puts "Halleluja Lord! I can see the light!" if $hosts_fqdn.any?
puts

=begin
File.open('/data01/puppet/enc/combined.dump', "r") do |f|
  @dumpfile = Marshal.load(f)
end
=end

encdump = []
File.open('/data01/puppet/enc/combined.yaml', "r") do |file|
  file.each_line do |line|
    encdump << line
  end
end
p encdump.inspect
