#!/usr/bin/env ruby
# frozen_string_literal: true

# Basic usage example for Aliyun E-HPC Ruby SDK
#
# This example demonstrates the basic functionality of the Aliyun E-HPC SDK
# including cluster management, job submission, and user management.

require 'bundler/setup'
require_relative '../lib/aliyun_ehpc'

# Configure the client
AliyunEhpc.configure do |config|
  config.access_key_id = ENV['ALIYUN_ACCESS_KEY_ID']
  config.access_key_secret = ENV['ALIYUN_ACCESS_KEY_SECRET']
  config.region = ENV['ALIYUN_EHPC_REGION'] || 'cn-hangzhou'
  config.endpoint = ENV['ALIYUN_EHPC_ENDPOINT'] || 'https://ehpc.cn-hangzhou.aliyuncs.com'
  config.log_level = :info
end

# Create a client
client = AliyunEhpc.client

puts "=== Aliyun E-HPC Ruby SDK Basic Usage Example ==="
puts "Client Info: #{client.info}"
puts

# Test connection
puts "Testing API connection..."
if client.test_connection
  puts "✓ Connection successful"
else
  puts "✗ Connection failed"
  exit 1
end
puts

# List clusters
puts "=== Listing Clusters ==="
begin
  clusters = client.clusters.list
  
  if clusters.empty?
    puts "No clusters found"
  else
    clusters.each do |cluster|
      puts "Cluster: #{cluster.name} (#{cluster.id})"
      puts "  State: #{cluster.state}"
      puts "  Nodes: #{cluster.total_nodes} (#{cluster.running_node_count} running)"
      puts "  Created: #{cluster.create_time}"
      puts
    end
  end
rescue AliyunEhpc::Error => e
  puts "Error listing clusters: #{e.message}"
end

# Use the first cluster for examples
cluster_id = ENV['ALIYUN_EHPC_CLUSTER_ID']
unless cluster_id
  clusters = client.clusters.list
  cluster_id = clusters.first&.id
end

if cluster_id
  puts "Using cluster: #{cluster_id}"
  puts
  
  # Get cluster details
  puts "=== Cluster Details ==="
  begin
    cluster = client.clusters.describe(cluster_id)
    puts "Name: #{cluster.name}"
    puts "Description: #{cluster.description}"
    puts "State: #{cluster.state}"
    puts "Region: #{cluster.region}"
    puts "Total Nodes: #{cluster.total_nodes}"
    puts "Running Nodes: #{cluster.running_node_count}"
    puts "Utilization: #{cluster.utilization}%"
    puts "Age: #{cluster.age_human}"
    puts
  rescue AliyunEhpc::Error => e
    puts "Error getting cluster details: #{e.message}"
  end
  
  # List queues
  puts "=== Listing Queues ==="
  begin
    queues = client.queues.list(cluster_id)
    
    if queues.empty?
      puts "No queues found"
    else
      queues.each do |queue|
        puts "Queue: #{queue.name}"
        puts "  State: #{queue.state}"
        puts "  Type: #{queue.type}"
        puts "  Priority: #{queue.priority}"
        puts "  Nodes: #{queue.total_nodes} (#{queue.available_nodes} available)"
        puts "  Jobs: #{queue.running_jobs} running, #{queue.queued_jobs} queued"
        puts "  Utilization: #{queue.utilization}%"
        puts
      end
    end
  rescue AliyunEhpc::Error => e
    puts "Error listing queues: #{e.message}"
  end
  
  # Submit a simple job
  puts "=== Submitting a Test Job ==="
  begin
    job_config = {
      'Name' => 'test-job-' + Time.now.strftime('%Y%m%d-%H%M%S'),
      'CommandLine' => 'echo "Hello from Aliyun E-HPC!" && sleep 30 && echo "Job completed"',
      'WorkingDir' => '/tmp',
      'StdoutRedirectPath' => '/tmp/test-job.out',
      'StderrRedirectPath' => '/tmp/test-job.err',
      'ClockTime' => 300, # 5 minutes
      'Thread' => 1,
      'MemSize' => 1024 # 1GB
    }
    
    job = client.jobs.submit(cluster_id, job_config)
    puts "✓ Job submitted successfully"
    puts "Job ID: #{job.id}"
    puts "Job Name: #{job.name}"
    puts "State: #{job.state}"
    puts "Queue: #{job.queue_name}"
    puts
    
    # Monitor job status
    puts "=== Monitoring Job Status ==="
    5.times do |i|
      sleep 2
      
      begin
        updated_job = client.jobs.describe(cluster_id, job.id)
        puts "Check #{i + 1}: #{updated_job.state}"
        
        if updated_job.finished?
          puts "Job finished with state: #{updated_job.state}"
          if updated_job.successful?
            puts "✓ Job completed successfully"
          else
            puts "✗ Job failed with exit code: #{updated_job.exit_code}"
          end
          break
        end
      rescue AliyunEhpc::Error => e
        puts "Error checking job status: #{e.message}"
        break
      end
    end
    puts
    
  rescue AliyunEhpc::Error => e
    puts "Error submitting job: #{e.message}"
  end
  
  # List recent jobs
  puts "=== Listing Recent Jobs ==="
  begin
    jobs = client.jobs.list(cluster_id, page_size: 5)
    
    if jobs.empty?
      puts "No jobs found"
    else
      jobs.each do |job|
        puts "Job: #{job.name} (#{job.id})"
        puts "  State: #{job.state}"
        puts "  Queue: #{job.queue_name}"
        puts "  User: #{job.user_name}"
        puts "  Submit Time: #{job.submit_time}"
        puts "  Duration: #{job.duration_human}" if job.start_time
        puts
      end
    end
  rescue AliyunEhpc::Error => e
    puts "Error listing jobs: #{e.message}"
  end
  
else
  puts "No cluster available for examples"
  puts "Please set ALIYUN_EHPC_CLUSTER_ID environment variable or create a cluster first"
end

puts "=== Example completed ==="
