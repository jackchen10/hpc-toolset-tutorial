# 阿里云 E-HPC Ruby 适配器代码设计

## 1. 项目结构设计

```
adapters/aliyun-ehpc/
├── lib/
│   ├── aliyun_ehpc/
│   │   ├── version.rb              # 版本信息
│   │   ├── configuration.rb        # 配置管理
│   │   ├── client.rb              # 主客户端类
│   │   ├── auth/
│   │   │   ├── signature.rb       # API 签名生成
│   │   │   └── credentials.rb     # 认证信息管理
│   │   ├── api/
│   │   │   ├── base.rb           # API 基础类
│   │   │   ├── cluster.rb        # 集群管理 API
│   │   │   ├── job.rb            # 作业管理 API
│   │   │   ├── user.rb           # 用户管理 API
│   │   │   └── queue.rb          # 队列管理 API
│   │   ├── models/
│   │   │   ├── cluster.rb        # 集群数据模型
│   │   │   ├── job.rb            # 作业数据模型
│   │   │   ├── user.rb           # 用户数据模型
│   │   │   └── queue.rb          # 队列数据模型
│   │   ├── adapters/
│   │   │   └── ondemand.rb       # OnDemand 适配器
│   │   ├── utils/
│   │   │   ├── logger.rb         # 日志工具
│   │   │   ├── retry.rb          # 重试机制
│   │   │   └── validator.rb      # 参数验证
│   │   └── errors.rb             # 异常定义
│   └── aliyun_ehpc.rb             # 主入口文件
├── config/
│   ├── aliyun_ehpc.yml           # 主配置文件
│   ├── user_mapping.yml          # 用户映射配置
│   └── clusters.yml              # 集群配置
├── spec/                         # RSpec 测试
├── examples/                     # 使用示例
├── docs/                         # 文档
├── Gemfile                       # Gem 依赖
├── aliyun_ehpc.gemspec          # Gem 规范
└── README.md                     # 项目说明
```

## 2. 核心类设计

### 2.1 主客户端类

```ruby
# lib/aliyun_ehpc/client.rb
module AliyunEhpc
  class Client
    attr_reader :configuration, :cluster_api, :job_api, :user_api
    
    def initialize(config = {})
      @configuration = Configuration.new(config)
      @auth_manager = Auth::Credentials.new(@configuration)
      
      # 初始化各个 API 模块
      @cluster_api = API::Cluster.new(@auth_manager, @configuration)
      @job_api = API::Job.new(@auth_manager, @configuration)
      @user_api = API::User.new(@auth_manager, @configuration)
    end
    
    # 便捷方法
    def clusters
      @cluster_api
    end
    
    def jobs
      @job_api
    end
    
    def users
      @user_api
    end
  end
end
```

### 2.2 配置管理类

```ruby
# lib/aliyun_ehpc/configuration.rb
module AliyunEhpc
  class Configuration
    DEFAULTS = {
      region: 'cn-hangzhou',
      api_version: '2018-04-12',
      timeout: 30,
      max_retries: 3,
      log_level: :info
    }.freeze
    
    attr_accessor :access_key_id, :access_key_secret, :region,
                  :api_version, :timeout, :max_retries, :log_level,
                  :endpoint, :cluster_id
    
    def initialize(options = {})
      # 从环境变量、配置文件或直接参数加载配置
      load_from_env
      load_from_file
      merge_options(options)
      validate!
    end
    
    def endpoint
      @endpoint ||= "https://ehpc.#{region}.aliyuncs.com"
    end
    
    private
    
    def load_from_env
      @access_key_id = ENV['ALIYUN_ACCESS_KEY_ID']
      @access_key_secret = ENV['ALIYUN_ACCESS_KEY_SECRET']
      @region = ENV['ALIYUN_REGION'] || DEFAULTS[:region]
    end
    
    def load_from_file
      config_file = File.join(Dir.pwd, 'config', 'aliyun_ehpc.yml')
      return unless File.exist?(config_file)
      
      config = YAML.load_file(config_file)
      env_config = config[ENV['RAILS_ENV'] || 'development'] || config['default']
      
      env_config&.each do |key, value|
        instance_variable_set("@#{key}", value) if respond_to?("#{key}=")
      end
    end
    
    def validate!
      raise ConfigurationError, "access_key_id is required" unless @access_key_id
      raise ConfigurationError, "access_key_secret is required" unless @access_key_secret
    end
  end
end
```

### 2.3 API 签名认证

```ruby
# lib/aliyun_ehpc/auth/signature.rb
module AliyunEhpc
  module Auth
    class Signature
      def initialize(access_key_secret)
        @access_key_secret = access_key_secret
      end
      
      def generate(method, params)
        # 添加公共参数
        params = add_common_params(params)
        
        # 构造规范化查询字符串
        query_string = build_query_string(params)
        
        # 构造待签名字符串
        string_to_sign = "#{method}&#{encode('/')}&#{encode(query_string)}"
        
        # 计算签名
        signature = Base64.encode64(
          OpenSSL::HMAC.digest('sha1', "#{@access_key_secret}&", string_to_sign)
        ).strip
        
        params['Signature'] = signature
        params
      end
      
      private
      
      def add_common_params(params)
        params.merge({
          'Format' => 'JSON',
          'Version' => '2018-04-12',
          'SignatureMethod' => 'HMAC-SHA1',
          'Timestamp' => Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ'),
          'SignatureVersion' => '1.0',
          'SignatureNonce' => SecureRandom.uuid
        })
      end
      
      def build_query_string(params)
        params.sort.map { |k, v| "#{encode(k)}=#{encode(v)}" }.join('&')
      end
      
      def encode(str)
        CGI.escape(str.to_s).gsub('+', '%20').gsub('*', '%2A').gsub('%7E', '~')
      end
    end
  end
end
```

### 2.4 API 基础类

```ruby
# lib/aliyun_ehpc/api/base.rb
module AliyunEhpc
  module API
    class Base
      include Utils::Logger
      include Utils::Retry
      
      def initialize(auth_manager, configuration)
        @auth = auth_manager
        @config = configuration
        @http_client = build_http_client
      end
      
      protected
      
      def make_request(action, params = {})
        params['Action'] = action
        signed_params = @auth.sign_request('POST', params)
        
        with_retry do
          response = @http_client.post(@config.endpoint, signed_params)
          handle_response(response)
        end
      end
      
      private
      
      def build_http_client
        require 'net/http'
        require 'uri'
        
        uri = URI(@config.endpoint)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.read_timeout = @config.timeout
        http
      end
      
      def handle_response(response)
        case response.code.to_i
        when 200
          JSON.parse(response.body)
        when 400..499
          handle_client_error(response)
        when 500..599
          handle_server_error(response)
        else
          raise APIError, "Unexpected response code: #{response.code}"
        end
      end
      
      def handle_client_error(response)
        error_data = JSON.parse(response.body) rescue {}
        error_code = error_data['Code']
        error_message = error_data['Message']
        
        case error_code
        when 'InvalidAccessKeyId.NotFound'
          raise AuthenticationError, error_message
        when 'Forbidden.SubUser'
          raise AuthorizationError, error_message
        when 'Throttling'
          raise RateLimitError, error_message
        else
          raise APIError.new(error_code, error_message)
        end
      end
      
      def handle_server_error(response)
        raise ServerError, "Server error: #{response.code} #{response.message}"
      end
    end
  end
end
```

### 2.5 作业管理 API

```ruby
# lib/aliyun_ehpc/api/job.rb
module AliyunEhpc
  module API
    class Job < Base
      def submit(cluster_id, job_config)
        params = {
          'ClusterId' => cluster_id,
          'CommandLine' => job_config[:command_line],
          'RunasUser' => job_config[:runas_user]
        }
        
        # 添加可选参数
        optional_params = %w[Name Priority PackagePath StdoutRedirectPath 
                           StderrRedirectPath JobQueue Node Cpu Task Thread 
                           Mem Gpu ClockTime Variables]
        
        optional_params.each do |param|
          key = param.downcase.to_sym
          params[param] = job_config[key] if job_config[key]
        end
        
        response = make_request('SubmitJob', params)
        Models::Job.new(response['JobId'], cluster_id, job_config)
      end
      
      def list(cluster_id, options = {})
        params = {
          'ClusterId' => cluster_id,
          'PageNumber' => options[:page_number] || 1,
          'PageSize' => options[:page_size] || 10
        }
        
        response = make_request('ListJobs', params)
        jobs_data = response['Jobs']['JobInfo'] || []
        
        jobs_data.map do |job_data|
          Models::Job.from_api_response(job_data)
        end
      end
      
      def describe(cluster_id, job_id)
        params = {
          'ClusterId' => cluster_id,
          'JobId' => job_id
        }
        
        response = make_request('DescribeJob', params)
        Models::Job.from_api_response(response['JobInfo'])
      end
      
      def delete(cluster_id, job_ids)
        job_ids = [job_ids] unless job_ids.is_a?(Array)
        
        params = {
          'ClusterId' => cluster_id,
          'Jobs' => job_ids.join(',')
        }
        
        make_request('DeleteJobs', params)
        true
      end
      
      def get_log(cluster_id, job_id, log_type = 'stdout')
        params = {
          'ClusterId' => cluster_id,
          'JobId' => job_id,
          'LogType' => log_type
        }
        
        response = make_request('GetJobLog', params)
        response['LogContent']
      end
    end
  end
end
```

### 2.6 数据模型

```ruby
# lib/aliyun_ehpc/models/job.rb
module AliyunEhpc
  module Models
    class Job
      attr_reader :id, :cluster_id, :name, :state, :command_line,
                  :submit_time, :start_time, :end_time, :runas_user,
                  :queue, :nodes, :cpus, :memory
      
      def initialize(id, cluster_id, attributes = {})
        @id = id
        @cluster_id = cluster_id
        @name = attributes[:name]
        @state = attributes[:state]
        @command_line = attributes[:command_line]
        @submit_time = parse_time(attributes[:submit_time])
        @start_time = parse_time(attributes[:start_time])
        @end_time = parse_time(attributes[:end_time])
        @runas_user = attributes[:runas_user]
        @queue = attributes[:queue]
        @nodes = attributes[:nodes]
        @cpus = attributes[:cpus]
        @memory = attributes[:memory]
      end
      
      def self.from_api_response(data)
        new(
          data['JobId'],
          data['ClusterId'],
          {
            name: data['Name'],
            state: data['State'],
            command_line: data['CommandLine'],
            submit_time: data['SubmitTime'],
            start_time: data['StartTime'],
            end_time: data['EndTime'],
            runas_user: data['RunasUser'],
            queue: data['Queue'],
            nodes: data['Node'],
            cpus: data['Cpu'],
            memory: data['Mem']
          }
        )
      end
      
      def running?
        @state == 'Running'
      end
      
      def completed?
        @state == 'Completed'
      end
      
      def failed?
        @state == 'Failed'
      end
      
      def queued?
        @state == 'Queued'
      end
      
      # OnDemand 状态映射
      def ondemand_state
        case @state
        when 'Running' then :running
        when 'Queued' then :queued
        when 'Completed' then :completed
        when 'Failed' then :failed
        when 'Cancelled' then :cancelled
        when 'Suspended' then :suspended
        else :unknown
        end
      end
      
      private
      
      def parse_time(time_str)
        return nil if time_str.nil? || time_str.empty?
        Time.parse(time_str)
      rescue ArgumentError
        nil
      end
    end
  end
end
```

## 3. OnDemand 适配器实现

```ruby
# lib/aliyun_ehpc/adapters/ondemand.rb
module AliyunEhpc
  module Adapters
    class OnDemand
      def initialize(config = {})
        @client = Client.new(config)
        @cluster_id = config[:cluster_id] || @client.configuration.cluster_id
        @job_script_parser = JobScriptParser.new
      end
      
      # OnDemand 作业提交接口
      def submit(script, after: [], afterok: [], afternotok: [], afterany: [])
        job_config = @job_script_parser.parse(script)
        job = @client.jobs.submit(@cluster_id, job_config)
        
        # 返回 OnDemand 期望的作业 ID 格式
        job.id
      end
      
      # OnDemand 作业信息查询接口
      def info(id)
        job = @client.jobs.describe(@cluster_id, id)
        
        # 转换为 OnDemand 期望的格式
        {
          id: job.id,
          status: job.ondemand_state,
          job_name: job.name,
          job_owner: job.runas_user,
          submission_time: job.submit_time,
          start_time: job.start_time,
          end_time: job.end_time,
          allocated_nodes: job.nodes,
          procs: job.cpus
        }
      end
      
      # OnDemand 作业状态查询接口
      def status(id)
        job = @client.jobs.describe(@cluster_id, id)
        job.ondemand_state
      end
      
      # OnDemand 作业控制接口
      def hold(id)
        # E-HPC 不支持 hold 操作，返回 false
        false
      end
      
      def release(id)
        # E-HPC 不支持 release 操作，返回 false
        false
      end
      
      def delete(id)
        @client.jobs.delete(@cluster_id, id)
        true
      end
      
      # OnDemand 集群信息接口
      def cluster_info
        cluster = @client.clusters.describe(@cluster_id)
        {
          name: cluster.name,
          host: cluster.login_nodes.first,
          job_adapter: 'aliyun_ehpc'
        }
      end
      
      private
      
      class JobScriptParser
        def parse(script_content)
          # 解析 SLURM 脚本，提取作业参数
          config = {
            command_line: extract_command(script_content),
            runas_user: extract_user(script_content) || ENV['USER']
          }
          
          # 解析 SLURM 指令
          script_content.scan(/^#SBATCH\s+(.+)$/) do |directive|
            parse_directive(directive.first, config)
          end
          
          config
        end
        
        private
        
        def extract_command(script)
          # 提取实际执行的命令（非注释行）
          lines = script.split("\n").reject { |line| line.strip.start_with?('#') }
          lines.join("\n").strip
        end
        
        def parse_directive(directive, config)
          case directive
          when /--job-name[=\s]+(.+)/
            config[:name] = $1.strip
          when /--partition[=\s]+(.+)/
            config[:job_queue] = $1.strip
          when /--nodes[=\s]+(\d+)/
            config[:node] = $1.to_i
          when /--ntasks[=\s]+(\d+)/
            config[:task] = $1.to_i
          when /--cpus-per-task[=\s]+(\d+)/
            config[:cpu] = $1.to_i
          when /--mem[=\s]+(\d+)([MG]?)/
            memory = $1.to_i
            unit = $2.upcase
            config[:mem] = case unit
                          when 'G' then "#{memory}GB"
                          when 'M', '' then "#{memory}MB"
                          else "#{memory}MB"
                          end
          when /--time[=\s]+(.+)/
            config[:clock_time] = parse_time_format($1.strip)
          end
        end
        
        def parse_time_format(time_str)
          # 转换 SLURM 时间格式到 E-HPC 格式
          # 例如: "1:30:00" -> "01:30:00"
          parts = time_str.split(':')
          case parts.length
          when 2
            "00:#{parts[0].rjust(2, '0')}:#{parts[1].rjust(2, '0')}"
          when 3
            "#{parts[0].rjust(2, '0')}:#{parts[1].rjust(2, '0')}:#{parts[2].rjust(2, '0')}"
          else
            "01:00:00"  # 默认1小时
          end
        end
      end
    end
  end
end
```

这个代码设计提供了完整的 Ruby 实现架构，包括了模块化设计、错误处理、配置管理和 OnDemand 集成等关键组件。
