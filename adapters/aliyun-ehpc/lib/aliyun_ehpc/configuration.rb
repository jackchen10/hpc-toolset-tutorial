# frozen_string_literal: true

module AliyunEhpc
  # Configuration management for AliyunEhpc
  class Configuration
    # Configuration attributes
    attr_accessor :access_key_id, :access_key_secret, :region, :endpoint,
                  :api_version, :timeout, :retry_count, :retry_delay,
                  :log_level, :logger, :cluster_id, :user_mapping,
                  :ssl_verify, :proxy_host, :proxy_port, :proxy_user, :proxy_pass
    
    # Default values
    DEFAULT_ENDPOINT = 'https://ehpc.cn-hangzhou.aliyuncs.com'
    DEFAULT_API_VERSION = '2018-04-12'
    DEFAULT_TIMEOUT = 30
    DEFAULT_RETRY_COUNT = 3
    DEFAULT_RETRY_DELAY = 1
    DEFAULT_LOG_LEVEL = :info
    DEFAULT_SSL_VERIFY = true
    
    def initialize(options = {})
      initialize_without_validation(options)
      validate!
    end

    def initialize_without_validation(options = {})
      # Set defaults first
      set_defaults

      # Load from configuration file
      load_from_config_file

      # Load from environment variables (override file config)
      load_from_env

      # Override with provided options (highest priority)
      options.each do |key, value|
        send("#{key}=", value) if respond_to?("#{key}=")
      end
    end
    
    # Load configuration from YAML file
    #
    # @param file_path [String] path to configuration file
    def load_from_file(file_path)
      return unless File.exist?(file_path)
      
      config_data = YAML.load_file(file_path)
      env = ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
      
      if config_data[env]
        config_data[env].each do |key, value|
          send("#{key}=", value) if respond_to?("#{key}=")
        end
      end
    end
    
    # Get endpoint URL
    #
    # @return [String] endpoint URL
    def endpoint_url
      @endpoint || default_endpoint
    end
    
    # Get default endpoint based on region
    #
    # @return [String] default endpoint URL
    def default_endpoint
      if @region
        "https://ehpc.#{@region}.aliyuncs.com"
      else
        DEFAULT_ENDPOINT
      end
    end
    
    # Check if configuration is valid
    #
    # @return [Boolean] true if valid
    def valid?
      !access_key_id.nil? && !access_key_secret.nil? && !region.nil?
    end
    
    # Validate configuration and raise error if invalid
    def validate!
      raise ConfigurationError, 'access_key_id is required' if access_key_id.nil? || access_key_id.empty?
      raise ConfigurationError, 'access_key_secret is required' if access_key_secret.nil? || access_key_secret.empty?
      raise ConfigurationError, 'region is required' if region.nil? || region.empty?
      
      validate_timeout!
      validate_retry_settings!
    end
    
    # Get configuration as hash
    #
    # @return [Hash] configuration hash
    def to_h
      {
        access_key_id: access_key_id,
        access_key_secret: '[REDACTED]',
        region: region,
        endpoint: endpoint_url,
        api_version: api_version,
        timeout: timeout,
        retry_count: retry_count,
        retry_delay: retry_delay,
        log_level: log_level,
        cluster_id: cluster_id,
        ssl_verify: ssl_verify
      }
    end
    
    private
    
    # Load configuration from environment variables
    def load_from_env
      @access_key_id = ENV['ALIYUN_ACCESS_KEY_ID']
      @access_key_secret = ENV['ALIYUN_ACCESS_KEY_SECRET']
      @region = ENV['ALIYUN_EHPC_REGION']
      @endpoint = ENV['ALIYUN_EHPC_ENDPOINT']
      @cluster_id = ENV['ALIYUN_EHPC_CLUSTER_ID']
      @timeout = ENV['ALIYUN_EHPC_TIMEOUT']&.to_i
      @retry_count = ENV['ALIYUN_EHPC_RETRY_COUNT']&.to_i
      @log_level = ENV['ALIYUN_EHPC_LOG_LEVEL']&.to_sym
    end
    
    # Set default values for unset attributes
    def set_defaults
      @api_version ||= DEFAULT_API_VERSION
      @timeout ||= DEFAULT_TIMEOUT
      @retry_count ||= DEFAULT_RETRY_COUNT
      @retry_delay ||= DEFAULT_RETRY_DELAY
      @log_level ||= DEFAULT_LOG_LEVEL
      @ssl_verify = DEFAULT_SSL_VERIFY if @ssl_verify.nil?
    end
    
    # Check if configuration file exists
    def config_file_exists?
      File.exist?(config_file_path)
    end
    
    # Get configuration file path
    def config_file_path
      File.join(Dir.pwd, 'config', 'aliyun_ehpc.yml')
    end
    
    # Load configuration from credentials file
    def load_from_config_file
      config_loader = AliyunEhpc::ConfigLoader.new
      if config_loader.config_exists?
        credentials = config_loader.load_credentials
        credentials.each do |key, value|
          next unless value

          # Convert symbol keys to string and set
          setter_method = "#{key}="
          if respond_to?(setter_method)
            send(setter_method, value)
          end
        end
      end
    end

    # Load configuration from file
    def load_config_file
      load_from_file(config_file_path)
    end
    
    # Validate timeout setting
    def validate_timeout!
      return unless timeout
      
      unless timeout.is_a?(Integer) && timeout > 0
        raise ConfigurationError, 'timeout must be a positive integer'
      end
    end
    
    # Validate retry settings
    def validate_retry_settings!
      if retry_count && (!retry_count.is_a?(Integer) || retry_count < 0)
        raise ConfigurationError, 'retry_count must be a non-negative integer'
      end
      
      if retry_delay && (!retry_delay.is_a?(Numeric) || retry_delay < 0)
        raise ConfigurationError, 'retry_delay must be a non-negative number'
      end
    end
  end
end
