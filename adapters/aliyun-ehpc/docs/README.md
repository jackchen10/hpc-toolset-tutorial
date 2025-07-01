# Aliyun E-HPC Ruby SDK Documentation

Welcome to the Aliyun E-HPC Ruby SDK documentation. This SDK provides a comprehensive Ruby interface for Alibaba Cloud's Elastic High Performance Computing (E-HPC) service with seamless Open OnDemand integration.

## Table of Contents

- [Getting Started](#getting-started)
- [Documentation](#documentation)
- [Examples](#examples)
- [API Reference](#api-reference)
- [Contributing](#contributing)
- [Support](#support)

## Getting Started

### Installation

Add this line to your application's Gemfile:

```ruby
gem 'aliyun_ehpc'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install aliyun_ehpc
```

### Quick Start

```ruby
require 'aliyun_ehpc'

# Configure the client
AliyunEhpc.configure do |config|
  config.access_key_id = ENV['ALIYUN_ACCESS_KEY_ID']
  config.access_key_secret = ENV['ALIYUN_ACCESS_KEY_SECRET']
  config.region = 'cn-hangzhou'
end

# Create a client and list clusters
client = AliyunEhpc.client
clusters = client.clusters.list

puts "Found #{clusters.size} clusters:"
clusters.each do |cluster|
  puts "  #{cluster.name} (#{cluster.state})"
end
```

### OnDemand Integration

```ruby
# Create OnDemand adapter
adapter = AliyunEhpc.client.ondemand_adapter(cluster_id: 'your-cluster-id')

# Submit SLURM job script
slurm_script = <<~SCRIPT
  #!/bin/bash
  #SBATCH --job-name=test
  #SBATCH --nodes=1
  #SBATCH --ntasks=1
  #SBATCH --time=01:00:00
  
  echo "Hello from E-HPC!"
SCRIPT

job_id = adapter.submit(slurm_script)
puts "Job submitted: #{job_id}"
```

## Documentation

### Core Documentation

- **[Configuration Guide](configuration.md)** - Complete configuration reference
- **[API Reference](api_reference.md)** - Detailed API documentation
- **[OnDemand Integration](ondemand_integration.md)** - OnDemand setup and usage

### Key Features

#### 🚀 **Complete E-HPC API Coverage**
- Cluster management (create, delete, scale, monitor)
- Job submission and monitoring
- User and queue management
- Resource allocation and monitoring

#### 🔗 **OnDemand Integration**
- SLURM script compatibility
- Seamless job submission
- Status monitoring
- Interactive app support

#### 🛡️ **Enterprise Ready**
- Comprehensive error handling
- Retry mechanisms with exponential backoff
- Structured logging and monitoring
- SSL/TLS security

#### ⚡ **Developer Friendly**
- Intuitive Ruby API
- Rich model objects
- Extensive documentation
- Complete test coverage

## Examples

The `examples/` directory contains practical examples:

### Basic Usage
```bash
ruby examples/basic_usage.rb
```
Demonstrates basic SDK functionality including cluster listing, job submission, and monitoring.

### OnDemand Integration
```bash
ruby examples/ondemand_integration.rb
```
Shows how to use the OnDemand adapter with SLURM job scripts.

### Cluster Management
```bash
ruby examples/cluster_management.rb
```
Covers cluster lifecycle management, scaling, and monitoring.

## API Reference

### Client

```ruby
# Global configuration
AliyunEhpc.configure do |config|
  config.access_key_id = 'your_key'
  config.access_key_secret = 'your_secret'
  config.region = 'cn-hangzhou'
end

# Create client
client = AliyunEhpc.client

# API access
clusters = client.clusters.list
jobs = client.jobs.list(cluster_id)
users = client.users.list(cluster_id)
queues = client.queues.list(cluster_id)
```

### Models

The SDK provides rich model objects:

```ruby
# Cluster model
cluster = client.clusters.describe(cluster_id)
puts cluster.name
puts cluster.state
puts cluster.utilization
puts cluster.age_human

# Job model
job = client.jobs.describe(cluster_id, job_id)
puts job.name
puts job.state
puts job.duration_human
puts job.successful?

# User model
user = client.users.describe(cluster_id, user_id)
puts user.name
puts user.active?
puts user.job_success_rate

# Queue model
queue = client.queues.describe(cluster_id, queue_name)
puts queue.name
puts queue.available?
puts queue.utilization
```

### Error Handling

```ruby
begin
  job = client.jobs.submit(cluster_id, job_config)
rescue AliyunEhpc::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue AliyunEhpc::APIError => e
  puts "API error: #{e.message}"
  puts "Request ID: #{e.request_id}"
rescue AliyunEhpc::NetworkError => e
  puts "Network error: #{e.message}"
rescue AliyunEhpc::Error => e
  puts "General error: #{e.message}"
end
```

## Architecture

### SDK Structure

```
AliyunEhpc
├── Client                 # Main client interface
├── Configuration         # Configuration management
├── API/                  # API client modules
│   ├── Cluster          # Cluster management
│   ├── Job              # Job management
│   ├── User             # User management
│   └── Queue            # Queue management
├── Models/              # Data models
│   ├── Cluster         # Cluster model
│   ├── Job             # Job model
│   ├── User            # User model
│   └── Queue           # Queue model
├── Adapters/           # Integration adapters
│   └── OnDemand        # OnDemand adapter
├── Auth/               # Authentication
│   ├── Credentials     # Credential management
│   └── Signature       # API signature
└── Utils/              # Utilities
    ├── Logger          # Logging
    ├── Retry           # Retry logic
    └── Validator       # Validation
```

### OnDemand Integration Flow

```
OnDemand Dashboard
       ↓
SLURM Job Script
       ↓
JobScriptParser (SLURM → E-HPC)
       ↓
OnDemand Adapter
       ↓
E-HPC API Client
       ↓
Aliyun E-HPC Service
```

## Configuration

### Environment Variables

```bash
# Required
export ALIYUN_ACCESS_KEY_ID="your_access_key_id"
export ALIYUN_ACCESS_KEY_SECRET="your_access_key_secret"
export ALIYUN_EHPC_REGION="cn-hangzhou"

# Optional
export ALIYUN_EHPC_CLUSTER_ID="your_default_cluster"
export ALIYUN_EHPC_TIMEOUT="30"
export ALIYUN_EHPC_RETRY_COUNT="3"
export ALIYUN_EHPC_LOG_LEVEL="info"
```

### Configuration File

Create `config/aliyun_ehpc.yml`:

```yaml
development:
  access_key_id: <%= ENV['ALIYUN_ACCESS_KEY_ID'] %>
  access_key_secret: <%= ENV['ALIYUN_ACCESS_KEY_SECRET'] %>
  region: cn-hangzhou
  timeout: 30
  log_level: debug

production:
  access_key_id: <%= ENV['ALIYUN_ACCESS_KEY_ID'] %>
  access_key_secret: <%= ENV['ALIYUN_ACCESS_KEY_SECRET'] %>
  region: <%= ENV['ALIYUN_EHPC_REGION'] %>
  timeout: 60
  log_level: warn
```

## Testing

Run the test suite:

```bash
bundle exec rspec
```

Run with coverage:

```bash
bundle exec rspec --format documentation
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -am 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Setup

```bash
git clone https://github.com/jackchen10/hpc-toolset-tutorial.git
cd hpc-toolset-tutorial/adapters/aliyun-ehpc
bundle install
bundle exec rspec
```

### Code Style

We use RuboCop for code style enforcement:

```bash
bundle exec rubocop
bundle exec rubocop --auto-correct
```

## Support

### Documentation
- [Configuration Guide](configuration.md)
- [API Reference](api_reference.md)
- [OnDemand Integration](ondemand_integration.md)

### Community
- GitHub Issues: Report bugs and request features
- GitHub Discussions: Ask questions and share ideas

### Commercial Support
- Aliyun Support: For cloud service issues
- Professional Services: Custom integration support

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

## Acknowledgments

- Alibaba Cloud E-HPC team for the excellent API
- Open OnDemand community for the integration framework
- Ruby community for the amazing ecosystem

---

**Happy Computing with Aliyun E-HPC! 🚀**
