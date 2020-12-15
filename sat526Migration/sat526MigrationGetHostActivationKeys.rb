#!/usr/bin/env ruby
require "xmlrpc/client"
require 'yaml'
require 'json'

begin
  @SATELLITE_URL = "http://sat5.example.com/rpc/api"
  @SATELLITE_LOGIN = "spacecmd"
  @SATELLITE_PASSWORD = "changeme"
  @HOSTNAMES = ARGV[0]

  # Enable support to run script in standalone mode with file input
  if ! $hosts.all?
    if ARGV.empty?
      puts "Script is run in Standalone mode.."
      puts "No filename supplied!"
      puts "Exiting..."
      exit
    else
      $hosts = Array.new
      File.open(@HOSTNAMES).each { |line| $hosts << line }
    end
  end

  # Declare global hash
  $host_activationkeys = Hash.new
  $hosts.each do |host|
    @client = XMLRPC::Client.new2(@SATELLITE_URL)
    @sessionkey = @client.call('auth.login', @SATELLITE_LOGIN, @SATELLITE_PASSWORD)

    # get the Id for a host
    @hostinfo = @client.call('system.getId',@sessionkey,host)
    #  puts @hostinfo.inspect
    @hostid = @hostinfo[0]['id'].to_i

    $host_activationkeys[host] = @client.call('system.listActivationKeys',@sessionkey,@hostid)
    #$host_activationkeys[host].uniq!
    print host + " "
    #puts $host_activationkeys[host].inspect
    puts " #{$host_activationkeys[host]['name']}"
  end

  # Logout from your session
  #@client.call(@client.call,@sessionkey)

rescue StandardError => e
  puts e.message
  puts e.backtrace.inspect
end
