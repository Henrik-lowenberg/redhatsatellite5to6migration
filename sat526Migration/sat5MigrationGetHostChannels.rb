#!/usr/bin/env ruby
require "xmlrpc/client"
require 'yaml'
require 'json'

begin
  @SATELLITE_URL = "http://sat5.example.com/rpc/api"
  @SATELLITE_LOGIN = "spacecmd"
  @SATELLITE_PASSWORD = "spacecmd"
  @HOSTNAMES = ARGV[0]

  if ARGV.empty? 
    puts "No filename supplied!"
    puts "Exiting..."
    exit
  else
    hostnames = Array.new
    File.open(@HOSTNAMES).each { |line| hostnames << line }
  end

  hostnames.each do |hostname|
    @client = XMLRPC::Client.new2(@SATELLITE_URL)
    @sessionkey = @client.call('auth.login', @SATELLITE_LOGIN, @SATELLITE_PASSWORD)

    # get the Id for a host
    @hostinfo = @client.call('system.getId',@sessionkey,hostname)
    #  puts @hostinfo.inspect
    puts hostname
    @hostid = @hostinfo[0]['id'].to_i

    @host_base_channel = @client.call('system.getSubscribedBaseChannel',@sessionkey,@hostid)
    #  puts @host_base_channel.inspect
    puts " #{@host_base_channel['name']}"

    @host_child_channels = @client.call('system.listSubscribedChildChannels',@sessionkey,@hostid)
    #  puts @host_child_channels
    @host_child_channels.each do |childchannel|
      puts " #{childchannel['name']}"
    end
  end
  puts
# Logout from your session
#@client.call(@client.call,@sessionkey)

rescue StandardError => e
  puts e.message
  puts e.backtrace.inspect
end
