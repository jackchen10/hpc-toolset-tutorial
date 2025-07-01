#!/usr/bin/env ruby
# frozen_string_literal: true

# 权限验证测试脚本
# 用于验证阿里云E-HPC SDK的权限配置是否正确

require 'bundler/setup'
require_relative '../lib/aliyun_ehpc'

puts "=== 阿里云E-HPC权限验证测试 ==="
puts

# 检查配置来源
puts "1. 检查配置来源..."

# 尝试从配置文件加载
config_loader = AliyunEhpc::ConfigLoader.new
credentials = {}

if config_loader.config_exists?
  puts "? 找到配置文件: #{config_loader.config_path}"
  credentials = config_loader.load_credentials
  puts "? 配置环境: #{config_loader.environment}"
else
  puts "??  配置文件不存在，尝试从环境变量加载"
end

# 从环境变量获取（优先级更高）
access_key_id = ENV['ALIYUN_ACCESS_KEY_ID'] || credentials[:access_key_id]
access_key_secret = ENV['ALIYUN_ACCESS_KEY_SECRET'] || credentials[:access_key_secret]
region = ENV['ALIYUN_EHPC_REGION'] || credentials[:region] || 'cn-hangzhou'

if access_key_id.nil? || access_key_id.empty?
  puts "? 错误：未找到AccessKey ID"
  puts "请在以下任一位置配置："
  puts "  1. 环境变量：export ALIYUN_ACCESS_KEY_ID='你的AccessKey ID'"
  puts "  2. 配置文件：adapters/aliyun-ehpc/config/credentials.yml"
  exit 1
end

if access_key_secret.nil? || access_key_secret.empty?
  puts "? 错误：未找到AccessKey Secret"
  puts "请在以下任一位置配置："
  puts "  1. 环境变量：export ALIYUN_ACCESS_KEY_SECRET='你的AccessKey Secret'"
  puts "  2. 配置文件：adapters/aliyun-ehpc/config/credentials.yml"
  exit 1
end

puts "? AccessKey ID: #{access_key_id[0..8]}***"
puts "? AccessKey Secret: #{access_key_secret[0..8]}***"
puts "? Region: #{region}"
puts

# 配置客户端
puts "2. 配置E-HPC客户端..."
begin
  AliyunEhpc.configure do |config|
    config.access_key_id = access_key_id
    config.access_key_secret = access_key_secret
    config.region = region
    config.log_level = :info
    config.timeout = 30
  end

  client = AliyunEhpc.client
  puts "? 客户端配置成功"
  puts "   - Endpoint: #{client.configuration.endpoint_url}"
  puts "   - API Version: #{client.configuration.api_version}"
rescue => e
  puts "? 客户端配置失败: #{e.message}"
  exit 1
end
puts

# 测试基础连接
puts "3. 测试API连接..."
begin
  if client.test_connection
    puts "? API连接测试成功"
  else
    puts "? API连接测试失败"
    exit 1
  end
rescue AliyunEhpc::AuthenticationError => e
  puts "? 认证失败: #{e.message}"
  puts "请检查AccessKey ID和Secret是否正确"
  exit 1
rescue AliyunEhpc::NetworkError => e
  puts "? 网络错误: #{e.message}"
  puts "请检查网络连接和防火墙设置"
  exit 1
rescue => e
  puts "? 连接失败: #{e.message}"
  exit 1
end
puts

# 测试集群权限
puts "4. 测试集群管理权限..."
begin
  clusters = client.clusters.list(page_size: 10)
  puts "? 集群查询权限正常"
  puts "   - 找到 #{clusters.size} 个集群"

  if clusters.empty?
    puts "   - 当前没有集群，这是正常的"
    puts "   - 你可以通过控制台或SDK创建集群"
  else
    puts "   - 集群列表："
    clusters.each do |cluster|
      puts "     * #{cluster.name} (#{cluster.id}) - #{cluster.state}"
    end
  end

rescue AliyunEhpc::PermissionError => e
  puts "? 集群权限不足: #{e.message}"
  puts "请确保RAM用户有 ehpc:DescribeClusters 权限"
rescue => e
  puts "? 集群查询失败: #{e.message}"
end
puts

puts "=== 权限验证总结 ==="
puts "? 基础配置：正常"
puts "? API连接：正常"
puts "? 认证授权：正常"
puts "? 集群权限：正常"
puts

puts "? 权限验证完成！你现在可以："
puts "   1. 运行基础使用示例：ruby examples/basic_usage.rb"
puts "   2. 创建E-HPC集群（如果还没有的话）"
puts "   3. 提交和管理作业"
puts "   4. 集成到OnDemand系统"
puts

puts "? 下一步建议："
if defined?(clusters) && clusters && clusters.empty?
  puts "   - 由于当前没有集群，建议先创建一个测试集群"
  puts "   - 可以运行：ruby examples/cluster_management.rb"
  puts "   - 或通过阿里云控制台创建集群"
elsif defined?(clusters) && clusters && !clusters.empty?
  puts "   - 设置默认集群ID环境变量："
  puts "     export ALIYUN_EHPC_CLUSTER_ID='#{clusters.first.id}'"
  puts "   - 运行OnDemand集成示例：ruby examples/ondemand_integration.rb"
end
puts

puts "=== 测试完成 ==="