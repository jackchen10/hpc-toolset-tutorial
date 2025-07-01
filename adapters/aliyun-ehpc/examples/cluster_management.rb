#!/usr/bin/env ruby
# frozen_string_literal: true

# Cluster management example for Aliyun E-HPC Ruby SDK
#
# This example demonstrates cluster lifecycle management including
# creation, scaling, monitoring, and deletion.

require 'bundler/setup'
require_relative '../lib/aliyun_ehpc'

# Configure the client
AliyunEhpc.configure do |config|
  config.access_key_id = ENV['ALIYUN_ACCESS_KEY_ID']
  config.access_key_secret = ENV['ALIYUN_ACCESS_KEY_SECRET']
  config.region = ENV['ALIYUN_EHPC_REGION'] || 'cn-hangzhou'
  config.log_level = :info
end

client = AliyunEhpc.client

puts "=== Aliyun E-HPC Cluster Management Example ==="
puts

# List existing clusters
puts "=== Current Clusters ==="
clusters = client.clusters.list
if clusters.empty?
  puts "No clusters found"
else
  clusters.each do |cluster|
    puts "Cluster: #{cluster.name} (#{cluster.id})"
    puts "  State: #{cluster.state}"
    puts "  Type: #{cluster.type}"
    puts "  Nodes: #{cluster.total_nodes}"
    puts "  Region: #{cluster.region}"
    puts "  Created: #{cluster.create_time}"
    puts "  Age: #{cluster.age_human}"
    puts
  end
end

# Example cluster configuration
cluster_config = {
  'Name' => 'test-cluster-' + Time.now.strftime('%Y%m%d-%H%M%S'),
  'Description' => 'Test cluster created by Ruby SDK example',
  'EhpcVersion' => '2.0.0',
  'OsTag' => 'CentOS_7.6_64',
  'InstanceType' => 'ecs.c6.large',
  'LoginCount' => 1,
  'ComputeCount' => 2,
  'VolumeType' => 'cloud_efficiency',
  'VolumeSize' => 40,
  'SchedulerType' => 'SLURM',
  'AccountType' => 'Normal'
}

puts "=== Creating Test Cluster ==="
puts "Configuration:"
cluster_config.each do |key, value|
  puts "  #{key}: #{value}"
end
puts

# Note: Cluster creation is commented out as it's expensive and time-consuming
# Uncomment the following block to actually create a cluster
=begin
begin
  puts "Creating cluster... (this may take 10-15 minutes)"
  new_cluster = client.clusters.create(cluster_config)
  
  puts "✓ Cluster creation initiated"
  puts "Cluster ID: #{new_cluster.id}"
  puts "Name: #{new_cluster.name}"
  puts "State: #{new_cluster.state}"
  puts
  
  # Monitor cluster creation
  puts "Monitoring cluster creation..."
  cluster_id = new_cluster.id
  
  30.times do |i|
    sleep 30 # Check every 30 seconds
    
    cluster = client.clusters.describe(cluster_id)
    puts "Check #{i + 1}: #{cluster.state}"
    
    if cluster.running?
      puts "✓ Cluster is now running!"
      break
    elsif cluster.exception?
      puts "✗ Cluster creation failed"
      break
    end
  end
  
rescue AliyunEhpc::Error => e
  puts "Error creating cluster: #{e.message}"
  cluster_id = nil
end
=end

# Use existing cluster for management examples
cluster_id = ENV['ALIYUN_EHPC_CLUSTER_ID']
if cluster_id.nil? && !clusters.empty?
  cluster_id = clusters.first.id
end

if cluster_id
  puts "Using cluster: #{cluster_id}"
  puts
  
  # Get detailed cluster information
  puts "=== Cluster Details ==="
  begin
    cluster = client.clusters.describe(cluster_id)
    
    puts "Basic Information:"
    puts "  Name: #{cluster.name}"
    puts "  ID: #{cluster.id}"
    puts "  State: #{cluster.state}"
    puts "  Type: #{cluster.type}"
    puts "  Region: #{cluster.region}"
    puts "  Zone: #{cluster.zone}"
    puts
    
    puts "Resource Information:"
    puts "  Total Nodes: #{cluster.total_nodes}"
    puts "  Running Nodes: #{cluster.running_node_count}"
    puts "  Max Nodes: #{cluster.max_node_count}"
    puts "  Utilization: #{cluster.utilization}%"
    puts
    
    puts "Network Configuration:"
    puts "  VPC ID: #{cluster.vpc_id}"
    puts "  Subnet ID: #{cluster.subnet_id}"
    puts "  Security Group: #{cluster.security_group_id}"
    puts
    
    puts "Software Configuration:"
    puts "  Scheduler: #{cluster.scheduler_type}"
    puts "  OS Tag: #{cluster.os_tag}"
    puts "  Client Version: #{cluster.client_version}"
    puts
    
  rescue AliyunEhpc::Error => e
    puts "Error getting cluster details: #{e.message}"
  end
  
  # Get cluster nodes
  puts "=== Cluster Nodes ==="
  begin
    nodes = client.clusters.nodes(cluster_id)
    
    if nodes.empty?
      puts "No nodes found"
    else
      nodes.each do |node|
        puts "Node: #{node['HostName'] || node['InstanceId']}"
        puts "  Status: #{node['Status']}"
        puts "  Role: #{node['Role']}"
        puts "  Instance Type: #{node['InstanceType']}"
        puts "  IP Address: #{node['IpAddress']}"
        puts "  Created: #{node['CreateTime']}"
        puts
      end
    end
  rescue AliyunEhpc::Error => e
    puts "Error getting cluster nodes: #{e.message}"
  end
  
  # Get cluster software
  puts "=== Installed Software ==="
  begin
    software = client.clusters.software(cluster_id)
    
    if software.empty?
      puts "No software packages found"
    else
      software.each do |pkg|
        puts "Package: #{pkg['Name']}"
        puts "  Version: #{pkg['Version']}"
        puts "  Status: #{pkg['Status']}"
        puts "  Description: #{pkg['Description']}"
        puts
      end
    end
  rescue AliyunEhpc::Error => e
    puts "Error getting cluster software: #{e.message}"
  end
  
  # Cluster scaling example (commented out for safety)
  puts "=== Cluster Scaling Example ==="
  puts "Current node count: #{cluster.total_nodes}"
  puts "Note: Scaling operations are commented out for safety"
  puts "To enable scaling, uncomment the scaling code blocks"
  puts
  
  =begin
  # Scale up cluster
  puts "Scaling up cluster..."
  begin
    result = client.clusters.scale(cluster_id, cluster.total_nodes + 1)
    if result
      puts "✓ Scale up operation initiated"
    else
      puts "✗ Scale up operation failed"
    end
  rescue AliyunEhpc::Error => e
    puts "Error scaling cluster: #{e.message}"
  end
  
  # Wait and then scale down
  sleep 60
  
  puts "Scaling down cluster..."
  begin
    result = client.clusters.scale(cluster_id, cluster.total_nodes)
    if result
      puts "✓ Scale down operation initiated"
    else
      puts "✗ Scale down operation failed"
    end
  rescue AliyunEhpc::Error => e
    puts "Error scaling cluster: #{e.message}"
  end
  =end
  
  # Get cluster metrics
  puts "=== Cluster Metrics ==="
  begin
    metrics = client.clusters.metrics(cluster_id, {
      metric_name: 'CPUUtilization',
      period: 300,
      start_time: (Time.now - 3600).iso8601,
      end_time: Time.now.iso8601
    })
    
    if metrics.empty?
      puts "No metrics data available"
    else
      puts "CPU Utilization (last hour):"
      metrics.each do |point|
        puts "  #{point['Timestamp']}: #{point['Average']}%"
      end
    end
    puts
    
  rescue AliyunEhpc::Error => e
    puts "Error getting cluster metrics: #{e.message}"
  end
  
  # Cluster operations examples
  puts "=== Cluster Operations ==="
  puts "Available operations:"
  puts "  - Start cluster: client.clusters.start(cluster_id)"
  puts "  - Stop cluster: client.clusters.stop(cluster_id)"
  puts "  - Delete cluster: client.clusters.delete(cluster_id)"
  puts
  puts "Note: These operations are not executed in this example"
  puts "Use them carefully as they affect cluster availability"
  puts
  
else
  puts "No cluster available for management examples"
  puts "Please set ALIYUN_EHPC_CLUSTER_ID environment variable or create a cluster first"
end

puts "=== Cluster Management Example Completed ==="
