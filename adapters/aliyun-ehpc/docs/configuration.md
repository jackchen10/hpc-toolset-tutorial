# Configuration Guide

This guide covers all configuration options for the Aliyun E-HPC Ruby SDK.

## Table of Contents

- [Basic Configuration](#basic-configuration)
- [Environment Variables](#environment-variables)
- [Configuration Files](#configuration-files)
- [Advanced Configuration](#advanced-configuration)
- [Security Configuration](#security-configuration)
- [OnDemand Integration](#ondemand-integration)
- [Troubleshooting](#troubleshooting)

## Basic Configuration

### Programmatic Configuration

```ruby
require 'aliyun_ehpc'

# Global configuration
AliyunEhpc.configure do |config|
  config.access_key_id = 'your_access_key_id'
  config.access_key_secret = 'your_access_key_secret'
  config.region = 'cn-hangzhou'
  config.cluster_id = 'your_default_cluster_id'
end

# Per-client configuration
client = AliyunEhpc.client(
  access_key_id: 'different_key_id',
  access_key_secret: 'different_key_secret',
  region: 'cn-beijing'
)
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `access_key_id` | String | nil | Aliyun access key ID |
| `access_key_secret` | String | nil | Aliyun access key secret |
| `region` | String | nil | Aliyun region |
| `endpoint` | String | Auto-generated | API endpoint URL |
| `api_version` | String | '2018-04-12' | E-HPC API version |
| `timeout` | Integer | 30 | Request timeout (seconds) |
| `retry_count` | Integer | 3 | Number of retries |
| `retry_delay` | Integer | 1 | Delay between retries (seconds) |
| `log_level` | Symbol | :info | Log level |
| `cluster_id` | String | nil | Default cluster ID |
| `ssl_verify` | Boolean | true | Verify SSL certificates |

## Environment Variables

The SDK automatically reads configuration from environment variables:

```bash
# Required credentials
export ALIYUN_ACCESS_KEY_ID="your_access_key_id"
export ALIYUN_ACCESS_KEY_SECRET="your_access_key_secret"

# Region and cluster
export ALIYUN_EHPC_REGION="cn-hangzhou"
export ALIYUN_EHPC_CLUSTER_ID="your_cluster_id"

# Optional settings
export ALIYUN_EHPC_ENDPOINT="https://ehpc.cn-hangzhou.aliyuncs.com"
export ALIYUN_EHPC_TIMEOUT="60"
export ALIYUN_EHPC_RETRY_COUNT="5"
export ALIYUN_EHPC_LOG_LEVEL="debug"

# Proxy settings (if needed)
export ALIYUN_EHPC_PROXY_HOST="proxy.example.com"
export ALIYUN_EHPC_PROXY_PORT="8080"
export ALIYUN_EHPC_PROXY_USER="username"
export ALIYUN_EHPC_PROXY_PASS="password"
```

### Environment Variable Priority

Configuration is loaded in this order (later values override earlier ones):
1. Default values
2. Environment variables
3. Configuration file
4. Programmatic configuration

## Configuration Files

### YAML Configuration

Create `config/aliyun_ehpc.yml`:

```yaml
# Development environment
development:
  access_key_id: <%= ENV['ALIYUN_ACCESS_KEY_ID'] %>
  access_key_secret: <%= ENV['ALIYUN_ACCESS_KEY_SECRET'] %>
  region: cn-hangzhou
  endpoint: https://ehpc.cn-hangzhou.aliyuncs.com
  timeout: 30
  retry_count: 3
  log_level: debug
  cluster_id: <%= ENV['ALIYUN_EHPC_CLUSTER_ID'] %>

# Production environment
production:
  access_key_id: <%= ENV['ALIYUN_ACCESS_KEY_ID'] %>
  access_key_secret: <%= ENV['ALIYUN_ACCESS_KEY_SECRET'] %>
  region: <%= ENV['ALIYUN_EHPC_REGION'] %>
  endpoint: <%= ENV['ALIYUN_EHPC_ENDPOINT'] %>
  timeout: 60
  retry_count: 5
  log_level: warn
  cluster_id: <%= ENV['ALIYUN_EHPC_CLUSTER_ID'] %>
```

### Loading Configuration Files

```ruby
# Automatic loading (looks for config/aliyun_ehpc.yml)
client = AliyunEhpc.client

# Manual loading
config = AliyunEhpc::Configuration.new
config.load_from_file('path/to/config.yml')
client = AliyunEhpc.client(config)
```

## Advanced Configuration

### Custom Endpoints

```ruby
AliyunEhpc.configure do |config|
  config.region = 'cn-hangzhou'
  config.endpoint = 'https://ehpc.cn-hangzhou.aliyuncs.com'
  
  # Or use custom endpoint
  config.endpoint = 'https://custom-endpoint.example.com'
end
```

### Timeout and Retry Configuration

```ruby
AliyunEhpc.configure do |config|
  # Network timeouts
  config.timeout = 60  # 60 seconds
  
  # Retry configuration
  config.retry_count = 5
  config.retry_delay = 2  # 2 seconds between retries
end
```

### Logging Configuration

```ruby
require 'logger'

# Built-in logger
AliyunEhpc.configure do |config|
  config.log_level = :debug  # :debug, :info, :warn, :error
end

# Custom logger
custom_logger = Logger.new('/var/log/aliyun-ehpc.log')
custom_logger.level = Logger::INFO
AliyunEhpc.logger = custom_logger

# Disable logging
AliyunEhpc.logger = Logger.new('/dev/null')
```

### Proxy Configuration

```ruby
AliyunEhpc.configure do |config|
  config.proxy_host = 'proxy.example.com'
  config.proxy_port = 8080
  config.proxy_user = 'username'  # optional
  config.proxy_pass = 'password'  # optional
end
```

## Security Configuration

### Credential Management

**Best Practices:**
1. Never hardcode credentials in source code
2. Use environment variables or secure credential stores
3. Rotate access keys regularly
4. Use least-privilege access policies

```ruby
# Good: Use environment variables
AliyunEhpc.configure do |config|
  config.access_key_id = ENV['ALIYUN_ACCESS_KEY_ID']
  config.access_key_secret = ENV['ALIYUN_ACCESS_KEY_SECRET']
end

# Better: Use credential providers
require 'aws-sdk-core'  # For credential providers

credentials = Aws::InstanceProfileCredentials.new
AliyunEhpc.configure do |config|
  config.access_key_id = credentials.access_key_id
  config.access_key_secret = credentials.secret_access_key
end
```

### SSL Configuration

```ruby
AliyunEhpc.configure do |config|
  # Enable SSL verification (default)
  config.ssl_verify = true
  
  # Disable SSL verification (not recommended for production)
  config.ssl_verify = false
end
```

### Access Control

Configure IAM policies for E-HPC access:

```json
{
  "Version": "1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ehpc:DescribeClusters",
        "ehpc:DescribeCluster",
        "ehpc:SubmitJob",
        "ehpc:ListJobs",
        "ehpc:GetJobLog",
        "ehpc:DeleteJobs"
      ],
      "Resource": "*"
    }
  ]
}
```

## OnDemand Integration

### Cluster Configuration

Create `/etc/ood/config/clusters.d/aliyun-ehpc.yml`:

```yaml
---
v2:
  metadata:
    title: "Aliyun E-HPC"
    description: "Aliyun Elastic High Performance Computing"
  login:
    host: "login-node-ip"
  job:
    adapter: "aliyun_ehpc"
    cluster: "<%= ENV['ALIYUN_EHPC_CLUSTER_ID'] %>"
    bin: "/usr/bin"
  custom:
    aliyun_ehpc:
      cluster_id: "<%= ENV['ALIYUN_EHPC_CLUSTER_ID'] %>"
      region: "<%= ENV['ALIYUN_EHPC_REGION'] %>"
      access_key_id: "<%= ENV['ALIYUN_ACCESS_KEY_ID'] %>"
      access_key_secret: "<%= ENV['ALIYUN_ACCESS_KEY_SECRET'] %>"
      timeout: 30
      retry_count: 3
      log_level: info
```

### User Mapping Configuration

Create `config/user_mapping.yml`:

```yaml
default:
  strategy: direct
  auto_create_users: false

users:
  # Direct mappings
  john: john.doe
  jane: jane.smith

groups:
  staff: ehpc-staff
  students: ehpc-students

queues:
  normal: normal
  gpu: gpu-queue
  debug: debug

resources:
  cpu:
    standard: ecs.c6.large
    compute: ecs.c6.xlarge
    memory: ecs.r6.large
    gpu: ecs.gn6i.large
```

### Queue Mapping Configuration

Create `config/clusters.yml`:

```yaml
default:
  max_nodes: 100
  max_walltime: 168  # hours
  default_queue: normal

clusters:
  production:
    cluster_id: ehpc-prod-001
    queues:
      normal:
        max_nodes: 50
        max_walltime: 72
        priority: 100
      gpu:
        max_nodes: 10
        max_walltime: 48
        priority: 150
        node_type: gpu
```

## Troubleshooting

### Configuration Validation

```ruby
# Check if configuration is valid
config = AliyunEhpc::Configuration.new
if config.valid?
  puts "Configuration is valid"
else
  puts "Configuration errors:"
  config.validation_errors.each { |error| puts "  - #{error}" }
end

# Test client connectivity
client = AliyunEhpc.client
if client.test_connection
  puts "Connection successful"
else
  puts "Connection failed"
end
```

### Debug Configuration

```ruby
# Enable debug logging
AliyunEhpc.configure do |config|
  config.log_level = :debug
end

# Print current configuration
client = AliyunEhpc.client
puts "Client info: #{client.info}"
puts "Configuration: #{client.configuration.to_h}"
```

### Common Issues

1. **Authentication Errors**
   ```ruby
   # Check credentials
   begin
     client = AliyunEhpc.client
     client.test_connection
   rescue AliyunEhpc::AuthenticationError => e
     puts "Authentication failed: #{e.message}"
     puts "Check access key ID and secret"
   end
   ```

2. **Network Issues**
   ```ruby
   # Test with longer timeout
   AliyunEhpc.configure do |config|
     config.timeout = 120
     config.retry_count = 5
   end
   ```

3. **SSL Issues**
   ```ruby
   # Disable SSL verification (not recommended)
   AliyunEhpc.configure do |config|
     config.ssl_verify = false
   end
   ```

### Environment-Specific Configuration

```ruby
# Rails application
case Rails.env
when 'development'
  AliyunEhpc.configure do |config|
    config.log_level = :debug
    config.timeout = 30
  end
when 'production'
  AliyunEhpc.configure do |config|
    config.log_level = :warn
    config.timeout = 60
    config.retry_count = 5
  end
end

# Sinatra application
configure :development do
  AliyunEhpc.configure do |config|
    config.log_level = :debug
  end
end

configure :production do
  AliyunEhpc.configure do |config|
    config.log_level = :error
  end
end
```

## Configuration Templates

### Minimal Configuration

```ruby
AliyunEhpc.configure do |config|
  config.access_key_id = ENV['ALIYUN_ACCESS_KEY_ID']
  config.access_key_secret = ENV['ALIYUN_ACCESS_KEY_SECRET']
  config.region = 'cn-hangzhou'
end
```

### Production Configuration

```ruby
AliyunEhpc.configure do |config|
  config.access_key_id = ENV['ALIYUN_ACCESS_KEY_ID']
  config.access_key_secret = ENV['ALIYUN_ACCESS_KEY_SECRET']
  config.region = ENV['ALIYUN_EHPC_REGION']
  config.cluster_id = ENV['ALIYUN_EHPC_CLUSTER_ID']
  config.timeout = 60
  config.retry_count = 5
  config.retry_delay = 2
  config.log_level = :warn
  config.ssl_verify = true
end
```

### Development Configuration

```ruby
AliyunEhpc.configure do |config|
  config.access_key_id = ENV['ALIYUN_ACCESS_KEY_ID']
  config.access_key_secret = ENV['ALIYUN_ACCESS_KEY_SECRET']
  config.region = 'cn-hangzhou'
  config.cluster_id = 'test-cluster'
  config.timeout = 30
  config.retry_count = 3
  config.log_level = :debug
end
```
