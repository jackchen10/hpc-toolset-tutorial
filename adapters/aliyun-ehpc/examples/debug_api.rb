#!/usr/bin/env ruby
# frozen_string_literal: true

# Debug API requests to understand the issue

require_relative '../lib/aliyun_ehpc'
require 'net/http'
require 'uri'
require 'json'

puts "=== Aliyun E-HPC API Debug ==="
puts

# Load configuration
config_loader = AliyunEhpc::ConfigLoader.new
credentials = config_loader.load_credentials

access_key_id = credentials[:access_key_id]
access_key_secret = credentials[:access_key_secret]
region = credentials[:region] || 'cn-hangzhou'

puts "Configuration:"
puts "  AccessKey ID: #{access_key_id[0..8]}***"
puts "  Region: #{region}"
puts

# Configure client
AliyunEhpc.configure do |config|
  config.access_key_id = access_key_id
  config.access_key_secret = access_key_secret
  config.region = region
  config.log_level = :debug
end

client = AliyunEhpc.client

# Debug: Check what parameters are being prepared
puts "=== Debug: Request Parameters ==="
cluster_api = client.clusters
base_params = cluster_api.send(:prepare_request_params, 'ListClusters', {})
puts "Base parameters:"
base_params.each do |key, value|
  puts "  #{key}: #{value}"
end
puts

# Debug: Check signature
auth_manager = client.auth_manager
signed_params = auth_manager.sign_request('GET', base_params)
puts "Signed parameters:"
signed_params.each do |key, value|
  puts "  #{key}: #{value}"
end
puts

# Debug: Check URL construction
query_string = URI.encode_www_form(signed_params)
endpoint_url = client.configuration.endpoint_url
uri = URI(endpoint_url)
uri.path = '/' if uri.path.empty?
uri.query = query_string

puts "Final URL:"
puts "  #{uri}"
puts "  Length: #{uri.to_s.length}"
puts

# Try manual HTTP request
puts "=== Manual HTTP Request ==="
begin
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  
  request = Net::HTTP::Get.new(uri)
  request['User-Agent'] = "AliyunEhpc-Ruby/#{AliyunEhpc::VERSION}"
  request['Accept'] = 'application/json'
  
  puts "Request headers:"
  request.each_header do |key, value|
    puts "  #{key}: #{value}"
  end
  puts
  
  response = http.request(request)
  
  puts "Response:"
  puts "  Status: #{response.code} #{response.message}"
  puts "  Headers:"
  response.each_header do |key, value|
    puts "    #{key}: #{value}"
  end
  puts "  Body (first 500 chars):"
  puts "    #{response.body[0..500]}"
  
rescue => e
  puts "Error: #{e.message}"
  puts "  Class: #{e.class.name}"
  puts "  Backtrace:"
  e.backtrace[0..5].each do |line|
    puts "    #{line}"
  end
end

puts
puts "=== Debug Complete ==="
