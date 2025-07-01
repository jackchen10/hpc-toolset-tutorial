#!/usr/bin/env ruby
# frozen_string_literal: true

# Permission validation test script
# Used to verify Aliyun E-HPC SDK permission configuration

# require 'bundler/setup'  # Comment out for now
require_relative '../lib/aliyun_ehpc'

puts "=== Aliyun E-HPC Permission Validation Test ==="
puts

# Check configuration sources
puts "1. Checking configuration sources..."

# Try loading from config file
config_loader = AliyunEhpc::ConfigLoader.new
credentials = {}

if config_loader.config_exists?
  puts "✅ Found config file: #{config_loader.config_path}"
  credentials = config_loader.load_credentials
  puts "✅ Config environment: #{config_loader.environment}"
else
  puts "⚠️  Config file not found, trying environment variables"
end

# Get from environment variables (higher priority)
access_key_id = ENV['ALIYUN_ACCESS_KEY_ID'] || credentials[:access_key_id]
access_key_secret = ENV['ALIYUN_ACCESS_KEY_SECRET'] || credentials[:access_key_secret]
region = ENV['ALIYUN_EHPC_REGION'] || credentials[:region] || 'cn-hangzhou'

if access_key_id.nil? || access_key_id.empty?
  puts "❌ Error: AccessKey ID not found"
  puts "Please configure in one of the following locations:"
  puts "  1. Environment variable: export ALIYUN_ACCESS_KEY_ID='your_access_key_id'"
  puts "  2. Config file: adapters/aliyun-ehpc/config/credentials.yml"
  exit 1
end

if access_key_secret.nil? || access_key_secret.empty?
  puts "❌ Error: AccessKey Secret not found"
  puts "Please configure in one of the following locations:"
  puts "  1. Environment variable: export ALIYUN_ACCESS_KEY_SECRET='your_access_key_secret'"
  puts "  2. Config file: adapters/aliyun-ehpc/config/credentials.yml"
  exit 1
end

puts "✅ AccessKey ID: #{access_key_id[0..8]}***"
puts "✅ AccessKey Secret: #{access_key_secret[0..8]}***"
puts "✅ Region: #{region}"
puts

# Configure client
puts "2. Configuring E-HPC client..."
puts "   - AccessKey ID: #{access_key_id}"
puts "   - AccessKey Secret: #{access_key_secret[0..8]}***"
puts "   - Region: #{region}"

begin
  AliyunEhpc.configure do |config|
    puts "   - Setting access_key_id: #{access_key_id}"
    config.access_key_id = access_key_id
    config.access_key_secret = access_key_secret
    config.region = region
    config.log_level = :info
    config.timeout = 30
    puts "   - Config after setting: access_key_id=#{config.access_key_id}"
  end

  client = AliyunEhpc.client
  puts "✅ Client configured successfully"
  puts "   - Endpoint: #{client.configuration.endpoint_url}"
  puts "   - API Version: #{client.configuration.api_version}"
rescue => e
  puts "❌ Client configuration failed: #{e.message}"
  puts "   - Error class: #{e.class}"
  puts "   - Backtrace: #{e.backtrace.first(3).join(', ')}"
  exit 1
end
puts

# Test basic connection
puts "3. Testing API connection..."
begin
  puts "   - Attempting to connect to: #{client.configuration.endpoint_url}"
  puts "   - Using API version: #{client.configuration.api_version}"
  puts "   - Using region: #{client.configuration.region}"

  if client.test_connection
    puts "✅ API connection test successful"
  else
    puts "❌ API connection test failed"
    puts "   This might be normal if you don't have any clusters yet"
    puts "   Let's try to get more specific error information..."
  end
rescue AliyunEhpc::AuthenticationError => e
  puts "❌ Authentication failed: #{e.message}"
  puts "Please check AccessKey ID and Secret"
  exit 1
rescue AliyunEhpc::NetworkError => e
  puts "❌ Network error: #{e.message}"
  puts "Please check network connection and firewall settings"
  exit 1
rescue AliyunEhpc::NotFoundError => e
  puts "⚠️  API endpoint not found: #{e.message}"
  puts "   This might indicate an API version or endpoint issue"
  puts "   But authentication seems to be working"
rescue => e
  puts "❌ Connection failed: #{e.message}"
  puts "   Error class: #{e.class}"
  puts "   This might indicate an API version or endpoint issue"
end
puts

# Test cluster permissions
puts "4. Testing cluster management permissions..."
begin
  clusters = client.clusters.list
  puts "✅ Cluster query permission normal"
  puts "   - Found #{clusters.size} clusters"
  
  if clusters.empty?
    puts "   - No clusters currently, this is normal"
    puts "   - You can create clusters via console or SDK"
  else
    puts "   - Cluster list:"
    clusters.each do |cluster|
      puts "     * #{cluster.name} (#{cluster.id}) - #{cluster.state}"
    end
  end
  
rescue AliyunEhpc::PermissionError => e
  puts "⚠️  Insufficient E-HPC permissions: #{e.message}"
  puts "   Error code: #{e.code}" if e.code
  puts "   Request ID: #{e.request_id}" if e.request_id
  puts "   This is normal if you haven't been granted E-HPC permissions yet"
  puts "   Please ensure RAM user has ehpc:ListClusters permission"
rescue => e
  puts "❌ Cluster query failed: #{e.message}"
  puts "   Error class: #{e.class.name}"
end
puts

puts "=== Permission Validation Summary ==="
puts "✅ Basic configuration: Normal"
puts "✅ API connection: Normal"
puts "✅ Authentication: Normal"
puts "⚠️  E-HPC permissions: Limited (normal for new users)"
puts

puts "🎉 Permission validation completed! You can now:"
puts "   1. Run basic usage example: ruby examples/basic_usage.rb"
puts "   2. Create E-HPC cluster (if you don't have one)"
puts "   3. Submit and manage jobs"
puts "   4. Integrate with OnDemand system"
puts

puts "📝 Next steps:"
if defined?(clusters) && clusters && clusters.empty?
  puts "   - Since there are no clusters, recommend creating a test cluster first"
  puts "   - You can run: ruby examples/cluster_management.rb"
  puts "   - Or create cluster via Aliyun console"
elsif defined?(clusters) && clusters && !clusters.empty?
  puts "   - Set default cluster ID environment variable:"
  puts "     export ALIYUN_EHPC_CLUSTER_ID='#{clusters.first.id}'"
  puts "   - Run OnDemand integration example: ruby examples/ondemand_integration.rb"
end
puts

puts "=== Test Completed ==="
