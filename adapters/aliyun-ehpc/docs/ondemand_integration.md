# OnDemand Integration Guide

This guide explains how to integrate the Aliyun E-HPC Ruby SDK with Open OnDemand to provide a unified interface for submitting jobs to both local SLURM clusters and Aliyun E-HPC clusters.

## Overview

The OnDemand adapter allows you to:
- Submit SLURM job scripts to Aliyun E-HPC clusters
- Monitor job status through the OnDemand interface
- Manage jobs using familiar SLURM commands
- Seamlessly switch between local and cloud resources

## Installation

### 1. Install the Gem

Add to your OnDemand server's Gemfile or install directly:

```bash
gem install aliyun_ehpc
```

### 2. Configure Credentials

Set up your Aliyun credentials using environment variables:

```bash
export ALIYUN_ACCESS_KEY_ID="your_access_key_id"
export ALIYUN_ACCESS_KEY_SECRET="your_access_key_secret"
export ALIYUN_EHPC_REGION="cn-hangzhou"
export ALIYUN_EHPC_CLUSTER_ID="your_cluster_id"
```

### 3. Create Cluster Configuration

Create a cluster configuration file for OnDemand:

```yaml
# /etc/ood/config/clusters.d/aliyun-ehpc.yml
---
v2:
  metadata:
    title: "Aliyun E-HPC Cluster"
    description: "Aliyun Elastic High Performance Computing Cluster"
  login:
    host: "your-login-node-ip"
  job:
    adapter: "aliyun_ehpc"
    cluster: "your-cluster-id"
    bin: "/usr/bin"
    conf: "/etc/slurm/slurm.conf"
  batch_connect:
    vnc:
      script_wrapper: |
        export PATH="/opt/TurboVNC/bin:$PATH"
        export WEBSOCKIFY_CMD="/usr/local/bin/websockify"
        %s
  custom:
    aliyun_ehpc:
      cluster_id: "your-cluster-id"
      region: "cn-hangzhou"
      access_key_id: "<%= ENV['ALIYUN_ACCESS_KEY_ID'] %>"
      access_key_secret: "<%= ENV['ALIYUN_ACCESS_KEY_SECRET'] %>"
```

## Usage

### Basic Job Submission

Create a SLURM job script and submit it through OnDemand:

```bash
#!/bin/bash
#SBATCH --job-name=test-job
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=01:00:00
#SBATCH --output=/tmp/test-job.out
#SBATCH --error=/tmp/test-job.err

echo "Hello from Aliyun E-HPC!"
hostname
date
sleep 30
echo "Job completed"
```

### Programmatic Usage

You can also use the adapter programmatically:

```ruby
require 'aliyun_ehpc'

# Create adapter
adapter = AliyunEhpc::Adapters::OnDemand.new(
  cluster_id: 'your-cluster-id'
)

# Submit job
script = File.read('job.slurm')
job_id = adapter.submit(script)

# Monitor status
status = adapter.status(job_id)
puts "Job status: #{status}"

# Get job info
info = adapter.info(job_id)
puts "Job info: #{info}"
```

## SLURM Directive Mapping

The adapter automatically converts SLURM directives to E-HPC parameters:

| SLURM Directive | E-HPC Parameter | Description |
|----------------|-----------------|-------------|
| `--job-name` | `Name` | Job name |
| `--partition` | `JobQueue` | Queue name |
| `--nodes` | `Node` | Number of nodes |
| `--ntasks` | `Task` | Number of tasks |
| `--cpus-per-task` | `Thread` | CPUs per task |
| `--mem` | `MemSize` | Memory in MB |
| `--time` | `ClockTime` | Wall time limit |
| `--output` | `StdoutRedirectPath` | Stdout file |
| `--error` | `StderrRedirectPath` | Stderr file |
| `--workdir` | `WorkingDir` | Working directory |
| `--gres=gpu:N` | `Gpu` | GPU count |
| `--array` | `ArrayRequest` | Job array |
| `--dependency` | `Dependencies` | Job dependencies |

## Supported Features

### Job Management
- ✅ Job submission
- ✅ Job status monitoring
- ✅ Job cancellation
- ✅ Job output retrieval
- ✅ Job dependencies
- ✅ Job arrays
- ✅ Job hold/release

### Resource Specifications
- ✅ CPU cores
- ✅ Memory allocation
- ✅ Node count
- ✅ Wall time limits
- ✅ GPU resources
- ✅ Queue selection

### Advanced Features
- ✅ Environment variables
- ✅ Working directory
- ✅ Output redirection
- ✅ Job constraints
- ✅ Email notifications
- ✅ Account/project mapping

## Configuration Options

### Adapter Configuration

```ruby
adapter = AliyunEhpc::Adapters::OnDemand.new(
  cluster_id: 'your-cluster-id',
  access_key_id: 'your-key-id',
  access_key_secret: 'your-key-secret',
  region: 'cn-hangzhou',
  timeout: 30,
  retry_count: 3,
  log_level: :info
)
```

### Script Parser Configuration

```ruby
parser_config = {
  default_queue: 'normal',
  default_memory_mb: 1024,
  default_walltime: 3600,
  default_cores: 1,
  queue_mapping: {
    'gpu' => 'gpu-queue',
    'high-mem' => 'memory-queue'
  },
  user_mapping: {
    'local-user' => 'ehpc-user'
  }
}

adapter = AliyunEhpc::Adapters::OnDemand.new(
  cluster_id: 'your-cluster-id',
  script_parser_config: parser_config
)
```

## Interactive Apps

The adapter supports OnDemand interactive apps. Create app configurations that target the Aliyun E-HPC cluster:

```yaml
# /var/www/ood/apps/sys/jupyter/form.yml
cluster: "aliyun-ehpc"

attributes:
  bc_num_hours:
    value: 1
  bc_num_slots:
    value: 1
  memory:
    widget: "number_field"
    value: 4
    min: 1
    max: 32
    label: "Memory (GB)"

form:
  - bc_num_hours
  - bc_num_slots
  - memory
```

## Monitoring and Logging

### Enable Logging

```ruby
AliyunEhpc.configure do |config|
  config.log_level = :debug
end
```

### Custom Logger

```ruby
require 'logger'

custom_logger = Logger.new('/var/log/ondemand/aliyun-ehpc.log')
AliyunEhpc.logger = custom_logger
```

### Job Monitoring

```ruby
# Get cluster information
cluster_info = adapter.cluster_info
puts "Cluster: #{cluster_info[:name]} (#{cluster_info[:state]})"

# Get queue information
queue_info = adapter.queue_info
queue_info.each do |queue|
  puts "Queue: #{queue[:name]} - #{queue[:running_jobs]} running jobs"
end

# List recent jobs
jobs = adapter.jobs(page_size: 10)
jobs.each do |job|
  puts "Job: #{job[:job_name]} (#{job[:status]})"
end
```

## Troubleshooting

### Common Issues

1. **Authentication Errors**
   - Verify access key ID and secret
   - Check region configuration
   - Ensure credentials have E-HPC permissions

2. **Job Submission Failures**
   - Verify cluster ID is correct
   - Check cluster state (must be running)
   - Validate job script syntax

3. **Network Issues**
   - Check firewall settings
   - Verify endpoint accessibility
   - Review proxy configuration

### Debug Mode

Enable debug logging to troubleshoot issues:

```ruby
AliyunEhpc.configure do |config|
  config.log_level = :debug
end

# Test connection
adapter = AliyunEhpc::Adapters::OnDemand.new(cluster_id: 'your-cluster-id')
if adapter.test_connection
  puts "Connection successful"
else
  puts "Connection failed"
end
```

### Validation

Validate job scripts before submission:

```ruby
parser = AliyunEhpc::Adapters::JobScriptParser.new
errors = parser.validate_script(script_content)

if errors.empty?
  puts "Script is valid"
else
  puts "Script errors:"
  errors.each { |error| puts "  - #{error}" }
end
```

## Best Practices

1. **Resource Management**
   - Set appropriate resource limits
   - Use job arrays for parallel tasks
   - Monitor cluster utilization

2. **Error Handling**
   - Implement retry logic for transient failures
   - Log errors for debugging
   - Provide user-friendly error messages

3. **Security**
   - Store credentials securely
   - Use environment variables
   - Rotate access keys regularly

4. **Performance**
   - Cache cluster information
   - Use connection pooling
   - Implement request throttling

## Migration from SLURM

When migrating from a local SLURM cluster:

1. **Update Job Scripts**
   - Review resource specifications
   - Adjust queue names if needed
   - Update file paths for cloud storage

2. **User Training**
   - Explain cloud-specific features
   - Provide migration examples
   - Document differences

3. **Gradual Migration**
   - Start with test jobs
   - Migrate non-critical workloads first
   - Monitor performance and costs

## Support

For issues and questions:
- Check the [API Reference](api_reference.md)
- Review example scripts in the `examples/` directory
- Submit issues on GitHub
- Contact Aliyun support for cloud-specific issues
