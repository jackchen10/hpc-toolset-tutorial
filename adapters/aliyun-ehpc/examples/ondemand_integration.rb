#!/usr/bin/env ruby
# frozen_string_literal: true

# OnDemand integration example for Aliyun E-HPC Ruby SDK
#
# This example demonstrates how to use the OnDemand adapter to submit
# SLURM-style job scripts to Aliyun E-HPC clusters.

require 'bundler/setup'
require_relative '../lib/aliyun_ehpc'

# Configure the client
AliyunEhpc.configure do |config|
  config.access_key_id = ENV['ALIYUN_ACCESS_KEY_ID']
  config.access_key_secret = ENV['ALIYUN_ACCESS_KEY_SECRET']
  config.region = ENV['ALIYUN_EHPC_REGION'] || 'cn-hangzhou'
  config.cluster_id = ENV['ALIYUN_EHPC_CLUSTER_ID']
  config.log_level = :info
end

# Create OnDemand adapter
adapter = AliyunEhpc.client.ondemand_adapter

puts "=== Aliyun E-HPC OnDemand Integration Example ==="
puts "Adapter Config: #{adapter.adapter_config}"
puts

# Test adapter connectivity
puts "Testing adapter connectivity..."
if adapter.test_connection
  puts "✓ Adapter connection successful"
else
  puts "✗ Adapter connection failed"
  exit 1
end
puts

# Get cluster information
puts "=== Cluster Information ==="
cluster_info = adapter.cluster_info
puts "Cluster: #{cluster_info[:name]}"
puts "State: #{cluster_info[:state]}"
puts "Nodes: #{cluster_info[:nodes]} (#{cluster_info[:running_nodes]} running)"
puts "Queues: #{cluster_info[:queues].join(', ')}"
puts

# Get queue information
puts "=== Queue Information ==="
queue_info = adapter.queue_info
queue_info.each do |queue|
  puts "Queue: #{queue[:name]}"
  puts "  State: #{queue[:state]}"
  puts "  Nodes: #{queue[:nodes]}"
  puts "  Jobs: #{queue[:running_jobs]} running, #{queue[:queued_jobs]} queued"
  puts
end

# Example 1: Simple SLURM script
puts "=== Example 1: Simple Job ==="
simple_script = <<~SCRIPT
  #!/bin/bash
  #SBATCH --job-name=simple-test
  #SBATCH --partition=normal
  #SBATCH --nodes=1
  #SBATCH --ntasks=1
  #SBATCH --cpus-per-task=1
  #SBATCH --mem=1G
  #SBATCH --time=00:05:00
  #SBATCH --output=/tmp/simple-test.out
  #SBATCH --error=/tmp/simple-test.err
  
  echo "Starting simple test job"
  echo "Hostname: $(hostname)"
  echo "Date: $(date)"
  echo "Working directory: $(pwd)"
  
  # Simulate some work
  sleep 10
  
  echo "Job completed successfully"
SCRIPT

begin
  job_id = adapter.submit(simple_script)
  puts "✓ Simple job submitted successfully"
  puts "Job ID: #{job_id}"
  
  # Monitor job status
  puts "Monitoring job status..."
  5.times do |i|
    sleep 3
    status = adapter.status(job_id)
    puts "Check #{i + 1}: #{status}"
    
    break if [:completed, :failed, :cancelled].include?(status)
  end
  
  # Get job info
  job_info = adapter.info(job_id)
  puts "Final job info: #{job_info}"
  puts
  
rescue AliyunEhpc::Error => e
  puts "Error with simple job: #{e.message}"
end

# Example 2: Multi-core job with dependencies
puts "=== Example 2: Multi-core Job ==="
multicore_script = <<~SCRIPT
  #!/bin/bash
  #SBATCH --job-name=multicore-test
  #SBATCH --partition=normal
  #SBATCH --nodes=1
  #SBATCH --ntasks=4
  #SBATCH --cpus-per-task=2
  #SBATCH --mem=4G
  #SBATCH --time=00:10:00
  #SBATCH --output=/tmp/multicore-test.out
  #SBATCH --error=/tmp/multicore-test.err
  
  echo "Starting multi-core test job"
  echo "Number of tasks: $SLURM_NTASKS"
  echo "CPUs per task: $SLURM_CPUS_PER_TASK"
  echo "Total CPUs: $((SLURM_NTASKS * SLURM_CPUS_PER_TASK))"
  
  # Parallel computation simulation
  for i in $(seq 1 $SLURM_NTASKS); do
    echo "Task $i starting on CPU core"
    sleep 5 &
  done
  
  wait
  echo "All tasks completed"
SCRIPT

begin
  job_id2 = adapter.submit(multicore_script)
  puts "✓ Multi-core job submitted successfully"
  puts "Job ID: #{job_id2}"
  puts
  
rescue AliyunEhpc::Error => e
  puts "Error with multi-core job: #{e.message}"
end

# Example 3: GPU job (if GPU queue is available)
puts "=== Example 3: GPU Job ==="
gpu_script = <<~SCRIPT
  #!/bin/bash
  #SBATCH --job-name=gpu-test
  #SBATCH --partition=gpu
  #SBATCH --nodes=1
  #SBATCH --ntasks=1
  #SBATCH --cpus-per-task=4
  #SBATCH --mem=8G
  #SBATCH --gres=gpu:1
  #SBATCH --time=00:15:00
  #SBATCH --output=/tmp/gpu-test.out
  #SBATCH --error=/tmp/gpu-test.err
  
  echo "Starting GPU test job"
  echo "Hostname: $(hostname)"
  
  # Check for GPU availability
  if command -v nvidia-smi &> /dev/null; then
    echo "GPU information:"
    nvidia-smi
  else
    echo "nvidia-smi not available, simulating GPU work"
  fi
  
  # Simulate GPU computation
  echo "Running GPU computation..."
  sleep 20
  
  echo "GPU job completed"
SCRIPT

begin
  job_id3 = adapter.submit(gpu_script)
  puts "✓ GPU job submitted successfully"
  puts "Job ID: #{job_id3}"
  puts
  
rescue AliyunEhpc::Error => e
  puts "GPU job submission failed (GPU queue may not be available): #{e.message}"
end

# Example 4: Job with dependencies
if defined?(job_id) && defined?(job_id2)
  puts "=== Example 4: Job with Dependencies ==="
  dependent_script = <<~SCRIPT
    #!/bin/bash
    #SBATCH --job-name=dependent-test
    #SBATCH --partition=normal
    #SBATCH --nodes=1
    #SBATCH --ntasks=1
    #SBATCH --cpus-per-task=1
    #SBATCH --mem=1G
    #SBATCH --time=00:05:00
    #SBATCH --output=/tmp/dependent-test.out
    #SBATCH --error=/tmp/dependent-test.err
    
    echo "Starting dependent job"
    echo "This job runs after the previous jobs complete"
    
    # Check if dependency files exist
    if [ -f /tmp/simple-test.out ]; then
      echo "Simple test output found"
    fi
    
    if [ -f /tmp/multicore-test.out ]; then
      echo "Multi-core test output found"
    fi
    
    echo "Dependent job completed"
  SCRIPT
  
  begin
    job_id4 = adapter.submit(dependent_script, afterok: [job_id, job_id2])
    puts "✓ Dependent job submitted successfully"
    puts "Job ID: #{job_id4}"
    puts "Dependencies: afterok:#{job_id},#{job_id2}"
    puts
    
  rescue AliyunEhpc::Error => e
    puts "Error with dependent job: #{e.message}"
  end
end

# List all jobs
puts "=== Current Jobs ==="
jobs = adapter.jobs(page_size: 10)
jobs.each do |job|
  puts "Job: #{job[:job_name]} (#{job[:id]})"
  puts "  Status: #{job[:status]}"
  puts "  Owner: #{job[:job_owner]}"
  puts "  Queue: #{job[:queue_name]}"
  puts "  Submit Time: #{job[:submit_time]}"
  puts
end

# Generate OnDemand cluster configuration
puts "=== OnDemand Cluster Configuration ==="
ondemand_config = adapter.to_ondemand_cluster_config
puts "Configuration for /etc/ood/config/clusters.d/aliyun-ehpc.yml:"
puts ondemand_config.to_yaml
puts

puts "=== OnDemand Integration Example Completed ==="
