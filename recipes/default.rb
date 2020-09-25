#
# Cookbook:: remote_audit
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.
ENV['AWS_ACCESS_KEY_ID'] = ""
ENV['AWS_SECRET_ACCESS_KEY_ID'] = ""
ENV['AWS_REGION'] = "ap-southeast-1"

remote_audit_scan 'aws scan' do
    profiles [
#      { source: 'chef', owner: 'delivery', profile: 'linux-baseline'}
      { source: 'chef', owner: 'delivery', profile: 'cis-aws-benchmark-level1'}
    ]
    node_name 'comp-rhel-BXsg'
    organization_name 'agency1'
#    target 'aws://ec2-user:r31nsta11@127.0.0.1'
    target 'aws://'
  end

#  { source: 'chef', owner: 'delivery', profile: 'cis-aws-benchmark-level1'}