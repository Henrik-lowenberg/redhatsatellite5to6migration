#!/usr/bin/env ruby
#
# Note! This has been adapted for cloudform use and needs to be
# rewritten

require 'uri'
require 'rest-client'
require 'json'
require 'timeout'

SATELLITE_HOST_ID = 'satellite_host_id'
organization_id = '1'
location_id = '3'
method = 'create_satellite_host'
satellite_host = 'sat6.example.com'
satellite_username = 'sat6user'
satellite_password = 'changeme'


#match on all reserved URI characters and escape them
def escape_uri(value)
  URI.escape(value, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
end

def get_infrastructure_environment(request)
  infrastructure_environment = request.options[:provision_environment]
end

#Retrieve the infrastructure configuration  
def retrieve_configuration(class_name, instance_name)
  instance_uri = "#{$evm.current_namespace}/Configuration/#{class_name}/#{instance_name}"
  $evm.log(:info, "the instance uri is: #{instance_uri}")
  instance = $evm.instantiate(instance_uri)
  error("Unable to retrieve satellite configuration: [#{instance_uri}]") unless instance
  
  config = {}
  instance.attributes.each { |k, _| config[k] = instance.decrypt(k) }
  config
end

def invoke_satellite_api(http_method, url, satellite_username, satellite_password, api_timeout, payload)
  
  begin
    Timeout.timeout(api_timeout) do
      result = JSON.load(RestClient::Request.execute({
        :method   => http_method,
        :url      => url,
        :user     => satellite_username,
        :password => satellite_password,
        :payload  => payload,
        :timeout  => api_timeout,
        :ssl_verify => false,
        :headers  => {:accept=>'version=2', :content_type => 'application/json'}
      }))
      $evm.log(:info, "Raw Satellite Result: [#{result}]")
      return result
    end
  end
end


def create_host(vm_host_name, ip_addr, vm_mac_address, satellite_hostgroup_id, build, organization_id, location_id, domain_id, subnet_id, managed, request, ifarray)
  log("interfacearray in create_host: #{ifarray}")
  host = {
    'name'                  => vm_host_name,
    'hostgroup_id'          => satellite_hostgroup_id,
    'build'                 => build, 
    'organization_id'       => organization_id,
    'location_id'           => location_id,
    'managed'               => managed,
    'domain_id'				=> domain_id,
    'interfaces_attributes' => ifarray,
  }
  
  value = {
    'host'                  => host,
  }
  
  infrastructure_environment = get_infrastructure_environment(request)
  infra_env_config           = retrieve_configuration('InfrastructureEnvironments', infrastructure_environment)
  satellite_host             = infra_env_config['satellite_host']
  url                        = "https://#{satellite_host}/api/hosts"
  satellite_username         = infra_env_config['satellite_username']
  satellite_password         = infra_env_config['satellite_password']
  api_timeout                = 60
  payload                    = value.to_json #V2 Satellite API requires JSON string
  http_method                = :post
  
  log("Invoke satellite API (#{url}) with payload: #{payload}")
  #log("Username = #{satellite_username} - Password = #{satellite_password} - url = #{url}")
  result = invoke_satellite_api(http_method, url, satellite_username, satellite_password, api_timeout, payload)
  satellite_host_id = result['id']
  
  return result, satellite_host_id
end

def save_satellite_host_id(prov, satellite_host_id)
  return unless prov
  vm = prov.destination
  if vm && satellite_host_id
    $evm.log(:info, "Saving Satellite Host ID to VMDB: [#{vm.name}][#{satellite_host_id}]")
    vm.custom_set(SATELLITE_HOST_ID, satellite_host_id)
  end
  prov.set_option(:satellite_host_id, satellite_host_id)
end


begin

  case $evm.root['vmdb_object_type']
    when 'miq_provision'  
      log(" I'm a miq_provision vmdb object type")
      prov = $evm.root['miq_provision']
      request = prov.miq_provision_request
      log("Request info miq_provision: #{request.inspect}")
      ipaddr = prov.get_option(:ip_addr)
    when 'service_template_provision_task'
      log(" I'm a service template provision task  vmdb object type")
      prov   = $evm.root['service_template_provision_task']
      request  = prov.miq_request
      log("Request info service_template_provision_task: #{request.inspect}")
      dialog_options = prov.options[:dialog] 
      ipaddr = dialog_options["dialog_ip_address"]
    end
  
  
  #prov    = $evm.root['miq_provision']
  #request = prov.miq_provision_request 
  
  # J. Szatanek addon: get ip address from provisionning request, saved during bluecat integration
  log("detected existing ipaddr = #{ipaddr}")
  #
  
  vm_name                 = $evm.current['vm_name']
  vm_mac_address          = $evm.current['vm_mac_address']
  satellite_hostgroup_id  = $evm.current['satellite_hostgroup_id']
  build                   = $evm.current['build']
  managed                 = $evm.current['managed']
  #TODO: improve how these 4 values are set or even fetch them from satellite more dynamic
  organization_id         = $evm.object['organization_id']
  location_id             = $evm.object['location_id']
  #domain_id		      = $evm.object['domain_id']
  #subnet_id  		      = $evm.object['subnet_id']
  domain_id		          = $evm.current['domainid']
  subnet_id  		      = $evm.current['subnetid']
  second_ip				  = $evm.current['secondip']
  second_mac		      = $evm.current['secondmac']
  second_subnetid		  = $evm.current['secondsubnetid']
  
  interfacearray = [ 
    {
      "primary" => true,
      "ip" => ipaddr,
      "mac" => vm_mac_address,
      "provision" => true,
      "managed" => managed,
      "virtual" => false,
      "subnet_id" => subnet_id,
     },
    ]
  log("Initial interface array: #{interfacearray}")
  
  unless second_ip.blank? or second_mac.blank? or second_subnetid.blank?
  	addinterface = [ 
      {
        "primary" => false,
        "ip" => second_ip,
        "mac" => second_mac,
        "provision" => false,
        "managed" => true,
        "subnet_id" => second_subnetid,
        },
      ]
    interfacearray = interfacearray + addinterface
    log("Extended interface array: #{interfacearray}")
  end
  
 
  
  result, satellite_host_id = create_host(vm_name, ipaddr, vm_mac_address, satellite_hostgroup_id, build, organization_id, location_id, domain_id, subnet_id, managed, request, interfacearray)
  
  log("Satellite Host ID: #{satellite_host_id}")
  
  save_satellite_host_id(prov, satellite_host_id) if prov.destination
  log("Satellite Host ID: #{satellite_host_id} Has been saved to the VMDB")
  
end


rescue StandardError => e
  puts e.message
  puts e.backtrace.inspect
end

