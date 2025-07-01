# API Reference

This document provides a comprehensive reference for the Aliyun E-HPC Ruby SDK API.

## Table of Contents

- [Client](#client)
- [Configuration](#configuration)
- [Cluster API](#cluster-api)
- [Job API](#job-api)
- [User API](#user-api)
- [Queue API](#queue-api)
- [OnDemand Adapter](#ondemand-adapter)
- [Models](#models)
- [Error Handling](#error-handling)

## Client

### AliyunEhpc.client(options = {})

Creates a new client instance.

**Parameters:**
- `options` (Hash): Configuration options

**Returns:** `AliyunEhpc::Client`

**Example:**
```ruby
client = AliyunEhpc.client(
  access_key_id: 'your_key_id',
  access_key_secret: 'your_key_secret',
  region: 'cn-hangzhou'
)
```

### Client Methods

#### #clusters
Returns the cluster API client.

**Returns:** `AliyunEhpc::API::Cluster`

#### #jobs
Returns the job API client.

**Returns:** `AliyunEhpc::API::Job`

#### #users
Returns the user API client.

**Returns:** `AliyunEhpc::API::User`

#### #queues
Returns the queue API client.

**Returns:** `AliyunEhpc::API::Queue`

#### #test_connection
Tests API connectivity.

**Returns:** `Boolean`

#### #info
Returns client information.

**Returns:** `Hash`

## Configuration

### AliyunEhpc.configure

Global configuration block.

**Example:**
```ruby
AliyunEhpc.configure do |config|
  config.access_key_id = ENV['ALIYUN_ACCESS_KEY_ID']
  config.access_key_secret = ENV['ALIYUN_ACCESS_KEY_SECRET']
  config.region = 'cn-hangzhou'
  config.timeout = 30
  config.retry_count = 3
end
```

### Configuration Options

- `access_key_id` (String): Aliyun access key ID
- `access_key_secret` (String): Aliyun access key secret
- `region` (String): Aliyun region
- `endpoint` (String): API endpoint URL
- `api_version` (String): API version (default: '2018-04-12')
- `timeout` (Integer): Request timeout in seconds (default: 30)
- `retry_count` (Integer): Number of retries (default: 3)
- `retry_delay` (Integer): Delay between retries (default: 1)
- `log_level` (Symbol): Log level (:debug, :info, :warn, :error)
- `cluster_id` (String): Default cluster ID

## Cluster API

### #list(params = {})

Lists all clusters.

**Parameters:**
- `params` (Hash): Optional query parameters
  - `page_size` (Integer): Number of results per page
  - `page_number` (Integer): Page number

**Returns:** `Array<AliyunEhpc::Models::Cluster>`

### #describe(cluster_id)

Gets cluster details.

**Parameters:**
- `cluster_id` (String): Cluster ID

**Returns:** `AliyunEhpc::Models::Cluster`

### #create(cluster_config)

Creates a new cluster.

**Parameters:**
- `cluster_config` (Hash): Cluster configuration
  - `Name` (String): Cluster name
  - `Description` (String): Cluster description
  - `EhpcVersion` (String): E-HPC version
  - `OsTag` (String): OS image tag
  - `InstanceType` (String): Instance type
  - `LoginCount` (Integer): Number of login nodes
  - `ComputeCount` (Integer): Number of compute nodes

**Returns:** `AliyunEhpc::Models::Cluster`

### #delete(cluster_id, options = {})

Deletes a cluster.

**Parameters:**
- `cluster_id` (String): Cluster ID
- `options` (Hash): Deletion options
  - `release_instance` (String): Whether to release instances

**Returns:** `Boolean`

### #start(cluster_id)

Starts a cluster.

**Parameters:**
- `cluster_id` (String): Cluster ID

**Returns:** `Boolean`

### #stop(cluster_id)

Stops a cluster.

**Parameters:**
- `cluster_id` (String): Cluster ID

**Returns:** `Boolean`

### #scale(cluster_id, node_count, options = {})

Scales cluster nodes.

**Parameters:**
- `cluster_id` (String): Cluster ID
- `node_count` (Integer): Target node count
- `options` (Hash): Scaling options

**Returns:** `Boolean`

### #nodes(cluster_id, options = {})

Gets cluster nodes.

**Parameters:**
- `cluster_id` (String): Cluster ID
- `options` (Hash): Query options

**Returns:** `Array<Hash>`

### #queues(cluster_id)

Gets cluster queues.

**Parameters:**
- `cluster_id` (String): Cluster ID

**Returns:** `Array<AliyunEhpc::Models::Queue>`

## Job API

### #submit(cluster_id, job_config)

Submits a job.

**Parameters:**
- `cluster_id` (String): Cluster ID
- `job_config` (Hash): Job configuration
  - `Name` (String): Job name
  - `CommandLine` (String): Command to execute
  - `WorkingDir` (String): Working directory
  - `StdoutRedirectPath` (String): Stdout file path
  - `StderrRedirectPath` (String): Stderr file path
  - `ClockTime` (Integer): Wall time limit in seconds
  - `Thread` (Integer): Number of CPU cores
  - `MemSize` (Integer): Memory in MB

**Returns:** `AliyunEhpc::Models::Job`

### #describe(cluster_id, job_id)

Gets job details.

**Parameters:**
- `cluster_id` (String): Cluster ID
- `job_id` (String): Job ID

**Returns:** `AliyunEhpc::Models::Job`

### #list(cluster_id, options = {})

Lists jobs.

**Parameters:**
- `cluster_id` (String): Cluster ID
- `options` (Hash): Query options
  - `page_size` (Integer): Number of results per page
  - `page_number` (Integer): Page number
  - `state` (String): Job state filter
  - `owner` (String): Job owner filter
  - `queue` (String): Queue name filter

**Returns:** `Array<AliyunEhpc::Models::Job>`

### #cancel(cluster_id, job_id)

Cancels a job.

**Parameters:**
- `cluster_id` (String): Cluster ID
- `job_id` (String): Job ID

**Returns:** `Boolean`

### #output(cluster_id, job_id, options = {})

Gets job output.

**Parameters:**
- `cluster_id` (String): Cluster ID
- `job_id` (String): Job ID
- `options` (Hash): Output options

**Returns:** `Hash`

## User API

### #list(cluster_id, options = {})

Lists users.

**Parameters:**
- `cluster_id` (String): Cluster ID
- `options` (Hash): Query options

**Returns:** `Array<AliyunEhpc::Models::User>`

### #describe(cluster_id, user_id)

Gets user details.

**Parameters:**
- `cluster_id` (String): Cluster ID
- `user_id` (String): User ID

**Returns:** `AliyunEhpc::Models::User`

### #create(cluster_id, user_config)

Creates a user.

**Parameters:**
- `cluster_id` (String): Cluster ID
- `user_config` (Hash): User configuration
  - `Name` (String): Username
  - `Password` (String): Password
  - `Group` (String): User group

**Returns:** `AliyunEhpc::Models::User`

### #delete(cluster_id, user_id)

Deletes a user.

**Parameters:**
- `cluster_id` (String): Cluster ID
- `user_id` (String): User ID

**Returns:** `Boolean`

## Queue API

### #list(cluster_id, options = {})

Lists queues.

**Parameters:**
- `cluster_id` (String): Cluster ID
- `options` (Hash): Query options

**Returns:** `Array<AliyunEhpc::Models::Queue>`

### #describe(cluster_id, queue_name)

Gets queue details.

**Parameters:**
- `cluster_id` (String): Cluster ID
- `queue_name` (String): Queue name

**Returns:** `AliyunEhpc::Models::Queue`

## OnDemand Adapter

### AliyunEhpc::Adapters::OnDemand.new(options = {})

Creates a new OnDemand adapter.

**Parameters:**
- `options` (Hash): Adapter options
  - `client` (AliyunEhpc::Client): E-HPC client
  - `cluster_id` (String): Cluster ID

### Adapter Methods

#### #submit(script, after: [], afterok: [], afternotok: [], afterany: [])

Submits a SLURM job script.

**Parameters:**
- `script` (String): SLURM job script content
- `after` (Array): Job dependencies (afterok)
- `afterok` (Array): Job dependencies (afterok)
- `afternotok` (Array): Job dependencies (afternotok)
- `afterany` (Array): Job dependencies (afterany)

**Returns:** `String` (job ID)

#### #status(job_id)

Gets job status.

**Parameters:**
- `job_id` (String): Job ID

**Returns:** `Symbol` (:queued, :running, :completed, :suspended, :undetermined)

#### #info(job_id)

Gets job information.

**Parameters:**
- `job_id` (String): Job ID

**Returns:** `Hash`

#### #delete(job_id)

Cancels a job.

**Parameters:**
- `job_id` (String): Job ID

**Returns:** `Boolean`

## Models

### AliyunEhpc::Models::Cluster

Represents an E-HPC cluster.

**Attributes:**
- `id` (String): Cluster ID
- `name` (String): Cluster name
- `state` (String): Cluster state
- `total_nodes` (Integer): Total node count
- `running_node_count` (Integer): Running node count

**Methods:**
- `#running?`: Check if cluster is running
- `#available?`: Check if cluster is available
- `#utilization`: Get utilization percentage

### AliyunEhpc::Models::Job

Represents an E-HPC job.

**Attributes:**
- `id` (String): Job ID
- `name` (String): Job name
- `state` (String): Job state
- `cluster_id` (String): Cluster ID
- `queue_name` (String): Queue name

**Methods:**
- `#running?`: Check if job is running
- `#completed?`: Check if job is completed
- `#successful?`: Check if job was successful

### AliyunEhpc::Models::User

Represents an E-HPC user.

**Attributes:**
- `id` (String): User ID
- `name` (String): User name
- `state` (String): User state
- `role` (String): User role

### AliyunEhpc::Models::Queue

Represents an E-HPC queue.

**Attributes:**
- `name` (String): Queue name
- `state` (String): Queue state
- `total_nodes` (Integer): Total nodes
- `running_jobs` (Integer): Running jobs

## Error Handling

The SDK defines several error classes:

- `AliyunEhpc::Error`: Base error class
- `AliyunEhpc::ConfigurationError`: Configuration errors
- `AliyunEhpc::AuthenticationError`: Authentication errors
- `AliyunEhpc::APIError`: API errors
- `AliyunEhpc::NetworkError`: Network errors
- `AliyunEhpc::ValidationError`: Validation errors
- `AliyunEhpc::AdapterError`: Adapter errors

**Example:**
```ruby
begin
  job = client.jobs.submit(cluster_id, job_config)
rescue AliyunEhpc::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue AliyunEhpc::APIError => e
  puts "API error: #{e.message}"
  puts "Request ID: #{e.request_id}"
rescue AliyunEhpc::Error => e
  puts "General error: #{e.message}"
end
```
