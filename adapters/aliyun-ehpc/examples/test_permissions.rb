#!/usr/bin/env ruby
# frozen_string_literal: true

# Ȩ����֤���Խű�
# ������֤������E-HPC SDK��Ȩ�������Ƿ���ȷ

require 'bundler/setup'
require_relative '../lib/aliyun_ehpc'

puts "=== ������E-HPCȨ����֤���� ==="
puts

# ���������Դ
puts "1. ���������Դ..."

# ���Դ������ļ�����
config_loader = AliyunEhpc::ConfigLoader.new
credentials = {}

if config_loader.config_exists?
  puts "? �ҵ������ļ�: #{config_loader.config_path}"
  credentials = config_loader.load_credentials
  puts "? ���û���: #{config_loader.environment}"
else
  puts "??  �����ļ������ڣ����Դӻ�����������"
end

# �ӻ���������ȡ�����ȼ����ߣ�
access_key_id = ENV['ALIYUN_ACCESS_KEY_ID'] || credentials[:access_key_id]
access_key_secret = ENV['ALIYUN_ACCESS_KEY_SECRET'] || credentials[:access_key_secret]
region = ENV['ALIYUN_EHPC_REGION'] || credentials[:region] || 'cn-hangzhou'

if access_key_id.nil? || access_key_id.empty?
  puts "? ����δ�ҵ�AccessKey ID"
  puts "����������һλ�����ã�"
  puts "  1. ����������export ALIYUN_ACCESS_KEY_ID='���AccessKey ID'"
  puts "  2. �����ļ���adapters/aliyun-ehpc/config/credentials.yml"
  exit 1
end

if access_key_secret.nil? || access_key_secret.empty?
  puts "? ����δ�ҵ�AccessKey Secret"
  puts "����������һλ�����ã�"
  puts "  1. ����������export ALIYUN_ACCESS_KEY_SECRET='���AccessKey Secret'"
  puts "  2. �����ļ���adapters/aliyun-ehpc/config/credentials.yml"
  exit 1
end

puts "? AccessKey ID: #{access_key_id[0..8]}***"
puts "? AccessKey Secret: #{access_key_secret[0..8]}***"
puts "? Region: #{region}"
puts

# ���ÿͻ���
puts "2. ����E-HPC�ͻ���..."
begin
  AliyunEhpc.configure do |config|
    config.access_key_id = access_key_id
    config.access_key_secret = access_key_secret
    config.region = region
    config.log_level = :info
    config.timeout = 30
  end

  client = AliyunEhpc.client
  puts "? �ͻ������óɹ�"
  puts "   - Endpoint: #{client.configuration.endpoint_url}"
  puts "   - API Version: #{client.configuration.api_version}"
rescue => e
  puts "? �ͻ�������ʧ��: #{e.message}"
  exit 1
end
puts

# ���Ի�������
puts "3. ����API����..."
begin
  if client.test_connection
    puts "? API���Ӳ��Գɹ�"
  else
    puts "? API���Ӳ���ʧ��"
    exit 1
  end
rescue AliyunEhpc::AuthenticationError => e
  puts "? ��֤ʧ��: #{e.message}"
  puts "����AccessKey ID��Secret�Ƿ���ȷ"
  exit 1
rescue AliyunEhpc::NetworkError => e
  puts "? �������: #{e.message}"
  puts "�����������Ӻͷ���ǽ����"
  exit 1
rescue => e
  puts "? ����ʧ��: #{e.message}"
  exit 1
end
puts

# ���Լ�ȺȨ��
puts "4. ���Լ�Ⱥ����Ȩ��..."
begin
  clusters = client.clusters.list(page_size: 10)
  puts "? ��Ⱥ��ѯȨ������"
  puts "   - �ҵ� #{clusters.size} ����Ⱥ"

  if clusters.empty?
    puts "   - ��ǰû�м�Ⱥ������������"
    puts "   - �����ͨ������̨��SDK������Ⱥ"
  else
    puts "   - ��Ⱥ�б�"
    clusters.each do |cluster|
      puts "     * #{cluster.name} (#{cluster.id}) - #{cluster.state}"
    end
  end

rescue AliyunEhpc::PermissionError => e
  puts "? ��ȺȨ�޲���: #{e.message}"
  puts "��ȷ��RAM�û��� ehpc:DescribeClusters Ȩ��"
rescue => e
  puts "? ��Ⱥ��ѯʧ��: #{e.message}"
end
puts

puts "=== Ȩ����֤�ܽ� ==="
puts "? �������ã�����"
puts "? API���ӣ�����"
puts "? ��֤��Ȩ������"
puts "? ��ȺȨ�ޣ�����"
puts

puts "? Ȩ����֤��ɣ������ڿ��ԣ�"
puts "   1. ���л���ʹ��ʾ����ruby examples/basic_usage.rb"
puts "   2. ����E-HPC��Ⱥ�������û�еĻ���"
puts "   3. �ύ�͹�����ҵ"
puts "   4. ���ɵ�OnDemandϵͳ"
puts

puts "? ��һ�����飺"
if defined?(clusters) && clusters && clusters.empty?
  puts "   - ���ڵ�ǰû�м�Ⱥ�������ȴ���һ�����Լ�Ⱥ"
  puts "   - �������У�ruby examples/cluster_management.rb"
  puts "   - ��ͨ�������ƿ���̨������Ⱥ"
elsif defined?(clusters) && clusters && !clusters.empty?
  puts "   - ����Ĭ�ϼ�ȺID����������"
  puts "     export ALIYUN_EHPC_CLUSTER_ID='#{clusters.first.id}'"
  puts "   - ����OnDemand����ʾ����ruby examples/ondemand_integration.rb"
end
puts

puts "=== ������� ==="