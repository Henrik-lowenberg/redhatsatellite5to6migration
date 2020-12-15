#!/usr/bin/env ruby
require "xmlrpc/client"
require 'yaml'
require 'json'

begin
  @SATELLITE_URL = "http://sat5.example.com/rpc/api"
  @SATELLITE_LOGIN = "spacecmd"
  @SATELLITE_PASSWORD = "spacecmd"
  @HOSTNAME = ARGV[0]

  if ARGV.empty? 
    puts "No hostname supplied!"
    puts "Exiting..."
    exit
  end
  @client = XMLRPC::Client.new2(@SATELLITE_URL)
  @sessionkey = @client.call('auth.login', @SATELLITE_LOGIN, @SATELLITE_PASSWORD)

  # get the Id for a host
  @hostinfo = @client.call('system.getId',@sessionkey,@HOSTNAME)
#  puts @hostinfo.inspect
  puts @HOSTNAME
  @hostid = @hostinfo[0]['id'].to_i

  @hostNetworkDevices = @client.call('system.getNetworkDevices',@sessionkey,@hostid)
#  puts @hostNetworkDevices
  for device in @hostNetworkDevices
    puts " #{device['ip']}"
    puts " #{device['interface']}"
    puts " #{device['netmask']}"
    puts " #{device['hardware_address']}"
  end

  puts
# Logout from your session
#@client.call(@client.call,@sessionkey)

rescue StandardError => e
  puts e.message
  puts e.backtrace.inspect
end
