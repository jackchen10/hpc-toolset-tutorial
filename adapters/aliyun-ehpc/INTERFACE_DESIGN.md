# 阿里云 E-HPC 接口结构设计

## 1. 整体架构设计

### 1.1 分层架构

```
┌─────────────────────────────────────────────────────────────┐
│                    OnDemand Dashboard                       │
│                   (用户界面层)                                │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                OnDemand Cluster                             │
│                 (集群抽象层)                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ SLURM       │  │ PBS         │  │ Aliyun E-HPC        │  │
│  │ Adapter     │  │ Adapter     │  │ Adapter             │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                E-HPC Ruby Client                            │
│                 (API客户端层)                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ Auth        │  │ Cluster     │  │ Job                 │  │
│  │ Manager     │  │ Manager     │  │ Manager             │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                 Aliyun E-HPC API                            │
│                  (云端服务层)                                │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 核心组件

#### 1.2.1 E-HPC Adapter (OnDemand 集成层)
- **职责**: 实现 OnDemand 集群接口，桥接本地调度器接口和云端 API
- **位置**: `/etc/ood/config/clusters.d/aliyun-ehpc.yml`
- **语言**: Ruby (符合 OnDemand 架构)

#### 1.2.2 E-HPC Ruby Client (API 客户端层)
- **职责**: 封装阿里云 E-HPC REST API，提供 Ruby 友好的接口
- **位置**: `adapters/aliyun-ehpc/lib/`
- **语言**: Ruby

#### 1.2.3 Configuration Manager (配置管理层)
- **职责**: 管理认证信息、集群配置、用户映射等
- **位置**: `adapters/aliyun-ehpc/config/`
- **语言**: Ruby + YAML

## 2. 接口设计规范

### 2.1 OnDemand 集群接口适配

#### 2.1.1 必需实现的接口

```ruby
# OnDemand 集群接口标准
class AliyunEhpcAdapter
  # 作业管理接口
  def submit(script, after: [], afterok: [], afternotok: [], afterany: [])
  def info(id)
  def status(id)
  def hold(id)
  def release(id)
  def delete(id)
  
  # 集群信息接口
  def cluster_info
  def queue_info
  def nodes_info
  
  # 用户接口
  def accounts
  def groups
end
```

#### 2.1.2 作业脚本转换

```ruby
# SLURM 脚本 → E-HPC API 参数转换
class JobScriptParser
  def parse_slurm_script(script_content)
    {
      command_line: extract_command,
      job_queue: extract_queue,
      node: extract_nodes,
      cpu: extract_cpus,
      mem: extract_memory,
      clock_time: extract_walltime,
      variables: extract_environment
    }
  end
end
```

### 2.2 E-HPC API 客户端接口

#### 2.2.1 认证管理

```ruby
module AliyunEhpc
  class AuthManager
    def initialize(access_key_id, access_key_secret, region)
    def generate_signature(method, params)
    def make_authenticated_request(action, params = {})
  end
end
```

#### 2.2.2 集群管理

```ruby
module AliyunEhpc
  class ClusterManager
    def list_clusters(page_number: 1, page_size: 10)
    def describe_cluster(cluster_id)
    def create_cluster(config)
    def delete_cluster(cluster_id)
    def list_queues(cluster_id)
    def list_nodes(cluster_id)
  end
end
```

#### 2.2.3 作业管理

```ruby
module AliyunEhpc
  class JobManager
    def submit_job(cluster_id, job_config)
    def list_jobs(cluster_id, options = {})
    def describe_job(cluster_id, job_id)
    def delete_jobs(cluster_id, job_ids)
    def get_job_log(cluster_id, job_id)
  end
end
```

#### 2.2.4 用户管理

```ruby
module AliyunEhpc
  class UserManager
    def list_users(cluster_id)
    def add_users(cluster_id, users)
    def delete_users(cluster_id, users)
    def modify_user(cluster_id, user_config)
  end
end
```

## 3. 数据模型设计

### 3.1 作业状态映射

```ruby
# E-HPC 状态 → OnDemand 状态映射
JOB_STATUS_MAPPING = {
  'Running'   => :running,
  'Queued'    => :queued,
  'Completed' => :completed,
  'Failed'    => :failed,
  'Cancelled' => :cancelled,
  'Suspended' => :suspended
}.freeze
```

### 3.2 集群配置模型

```yaml
# /etc/ood/config/clusters.d/aliyun-ehpc.yml
v2:
  metadata:
    title: "Aliyun E-HPC Cluster"
    url: "https://ehpc.cn-hangzhou.aliyuncs.com"
    hidden: false
  
  login:
    host: "frontend.cluster.aliyun.com"
  
  job:
    adapter: "aliyun_ehpc"
    cluster_id: "ehpc-cluster-001"
    bin: "/usr/local/bin"
    conf: "/etc/aliyun-ehpc/config.yml"
    
  batch_connect:
    basic:
      script_wrapper: |
        #!/bin/bash
        %s
    vnc:
      script_wrapper: |
        #!/bin/bash
        export DISPLAY=:1
        %s
```

### 3.3 用户映射模型

```ruby
class UserMapping
  def initialize(config_file)
  
  def local_to_ehpc_user(local_username)
    # 本地用户名 → E-HPC 用户名映射
  end
  
  def ehpc_to_local_user(ehpc_username)
    # E-HPC 用户名 → 本地用户名映射
  end
end
```

## 4. 错误处理设计

### 4.1 异常层次结构

```ruby
module AliyunEhpc
  class Error < StandardError; end
  
  class AuthenticationError < Error; end
  class AuthorizationError < Error; end
  class NetworkError < Error; end
  class APIError < Error
    attr_reader :code, :message, :request_id
  end
  
  class ClusterNotFoundError < APIError; end
  class JobNotFoundError < APIError; end
  class QuotaExceededError < APIError; end
end
```

### 4.2 重试机制

```ruby
class RetryableRequest
  def initialize(max_retries: 3, backoff_factor: 2)
  
  def execute(&block)
    retries = 0
    begin
      yield
    rescue NetworkError, Timeout::Error => e
      retries += 1
      if retries <= @max_retries
        sleep(@backoff_factor ** retries)
        retry
      else
        raise e
      end
    end
  end
end
```

## 5. 配置管理设计

### 5.1 配置文件结构

```yaml
# config/aliyun-ehpc.yml
default: &default
  access_key_id: <%= ENV['ALIYUN_ACCESS_KEY_ID'] %>
  access_key_secret: <%= ENV['ALIYUN_ACCESS_KEY_SECRET'] %>
  region: cn-hangzhou
  
  api:
    endpoint: https://ehpc.cn-hangzhou.aliyuncs.com
    version: "2018-04-12"
    timeout: 30
    max_retries: 3
  
  cluster:
    default_cluster_id: ehpc-cluster-001
    default_queue: workq
    
  user_mapping:
    strategy: "ldap"  # ldap, file, auto
    mapping_file: "config/user_mapping.yml"
    
  file_transfer:
    oss_bucket: hpc-data-bucket
    temp_directory: /tmp/ehpc-transfer

development:
  <<: *default
  
production:
  <<: *default
  region: cn-beijing
```

### 5.2 环境变量管理

```bash
# .env 文件
ALIYUN_ACCESS_KEY_ID=your_access_key_id
ALIYUN_ACCESS_KEY_SECRET=your_access_key_secret
ALIYUN_REGION=cn-hangzhou
EHPC_CLUSTER_ID=ehpc-cluster-001
```

## 6. 日志和监控设计

### 6.1 日志结构

```ruby
class Logger
  def log_api_request(action, params, response_time, status)
    {
      timestamp: Time.now.iso8601,
      level: 'INFO',
      component: 'aliyun-ehpc-adapter',
      action: action,
      params: sanitize_params(params),
      response_time_ms: response_time,
      status: status,
      request_id: response['RequestId']
    }
  end
end
```

### 6.2 性能监控

```ruby
class PerformanceMonitor
  def track_api_call(action)
    start_time = Time.now
    result = yield
    end_time = Time.now
    
    log_performance_metric(
      action: action,
      duration: (end_time - start_time) * 1000,
      success: result.success?
    )
    
    result
  end
end
```

## 7. 安全设计

### 7.1 认证信息保护

```ruby
class SecureConfig
  def self.load_credentials
    # 从加密配置文件或环境变量加载
    # 支持 Vault、AWS Secrets Manager 等
  end
  
  def self.encrypt_sensitive_data(data)
    # 使用 AES 加密敏感数据
  end
end
```

### 7.2 API 调用安全

```ruby
class SecureAPIClient
  def initialize
    @rate_limiter = RateLimiter.new(requests_per_minute: 100)
    @request_validator = RequestValidator.new
  end
  
  def make_request(action, params)
    @rate_limiter.check_limit!
    @request_validator.validate!(action, params)
    
    # 执行 API 调用
  end
end
```

这个接口设计为后续的 Ruby 实现提供了清晰的架构指导和实现规范。
