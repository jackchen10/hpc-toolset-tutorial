# Aliyun E-HPC Ruby SDK

A comprehensive Ruby SDK for Alibaba Cloud Elastic High Performance Computing (E-HPC) service with Open OnDemand integration support.

## Features

- **Complete E-HPC API Coverage**: Full support for cluster, job, user, and queue management
- **OnDemand Integration**: Seamless integration with Open OnDemand portal
- **Authentication**: Secure API authentication with AccessKey/SecretKey
- **Error Handling**: Comprehensive error handling and retry mechanisms
- **Logging**: Built-in logging and monitoring support
- **Configuration**: Flexible configuration management
- **Testing**: Full test coverage with RSpec

## Installation

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

## Quick Start

### Basic Configuration

```ruby
require 'aliyun_ehpc'

# Configure the client
AliyunEhpc.configure do |config|
  config.access_key_id = 'your_access_key_id'
  config.access_key_secret = 'your_access_key_secret'
  config.region = 'cn-hangzhou'
  config.endpoint = 'https://ehpc.cn-hangzhou.aliyuncs.com'
end

# Create a client
client = AliyunEhpc.client
```

### Cluster Management

```ruby
# List clusters
clusters = client.clusters.list

# Get cluster details
cluster = client.clusters.describe('cluster-id')

# Create a cluster
cluster_config = {
  name: 'my-cluster',
  description: 'Test cluster',
  # ... other configuration
}
new_cluster = client.clusters.create(cluster_config)
```

### Job Management

```ruby
# Submit a job
job_config = {
  name: 'my-job',
  command: 'echo "Hello World"',
  # ... other configuration
}
job = client.jobs.submit('cluster-id', job_config)

# Check job status
job_status = client.jobs.describe('cluster-id', 'job-id')

# List jobs
jobs = client.jobs.list('cluster-id')
```

### OnDemand Integration

```ruby
# Create OnDemand adapter
adapter = AliyunEhpc::Adapters::OnDemand.new(
  cluster_id: 'your-cluster-id'
)

# Submit SLURM script
slurm_script = <<~SCRIPT
  #!/bin/bash
  #SBATCH --job-name=test
  #SBATCH --nodes=1
  #SBATCH --ntasks=1
  #SBATCH --time=01:00:00
  
  echo "Hello from E-HPC!"
SCRIPT

job_id = adapter.submit(slurm_script)
```

## Configuration

### Environment Variables

```bash
export ALIYUN_ACCESS_KEY_ID="your_access_key_id"
export ALIYUN_ACCESS_KEY_SECRET="your_access_key_secret"
export ALIYUN_EHPC_REGION="cn-hangzhou"
export ALIYUN_EHPC_ENDPOINT="https://ehpc.cn-hangzhou.aliyuncs.com"
```

### Configuration File

Create `config/aliyun_ehpc.yml`:

```yaml
development:
  access_key_id: <%= ENV['ALIYUN_ACCESS_KEY_ID'] %>
  access_key_secret: <%= ENV['ALIYUN_ACCESS_KEY_SECRET'] %>
  region: cn-hangzhou
  endpoint: https://ehpc.cn-hangzhou.aliyuncs.com
  timeout: 30
  retry_count: 3
  log_level: info

production:
  access_key_id: <%= ENV['ALIYUN_ACCESS_KEY_ID'] %>
  access_key_secret: <%= ENV['ALIYUN_ACCESS_KEY_SECRET'] %>
  region: cn-hangzhou
  endpoint: https://ehpc.cn-hangzhou.aliyuncs.com
  timeout: 60
  retry_count: 5
  log_level: warn
```

## Documentation

- [API Reference](docs/api_reference.md)
- [OnDemand Integration Guide](docs/ondemand_integration.md)
- [Configuration Guide](docs/configuration.md)
- [Examples](examples/)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jackchen10/hpc-toolset-tutorial.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
