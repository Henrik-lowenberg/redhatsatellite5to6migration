#!/usr/bin/env ruby
# # By: Henrik Lowenberg
# # Description: 
# # Main script functions:
# # Migrate hosts from Satellite 5 to Satellite 6
# # 
# # This file: template.rb
# # Function: 
#   
#
# Step 1: Get and sort file with hostnames into an array
# Step 2: Get host's ENC variables stored in AD
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

# Method Definition:
#   
