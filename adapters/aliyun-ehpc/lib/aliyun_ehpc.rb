# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'
require 'openssl'
require 'base64'
require 'time'
require 'yaml'
require 'logger'

# Aliyun E-HPC Ruby SDK
# 
# This gem provides a Ruby interface to Alibaba Cloud E-HPC (Elastic High Performance Computing) service.
# It includes adapters for Open OnDemand integration and comprehensive API client functionality.
#
# @author HPC Toolset Tutorial Project
# @version 1.0.0
module AliyunEhpc
  # Version information
  VERSION = '1.0.0'
  
  # Default configuration
  DEFAULT_CONFIG = {
    endpoint: 'https://ehpc.cn-hangzhou.aliyuncs.com',
    api_version: '2018-04-12',
    timeout: 30,
    retry_count: 3,
    retry_delay: 1,
    log_level: :info
  }.freeze
  
  # Load all required files
  require_relative 'aliyun_ehpc/version'
  require_relative 'aliyun_ehpc/errors'
  require_relative 'aliyun_ehpc/configuration'
  require_relative 'aliyun_ehpc/config_loader'
  require_relative 'aliyun_ehpc/utils/logger'
  require_relative 'aliyun_ehpc/utils/retry'
  require_relative 'aliyun_ehpc/utils/validator'
  require_relative 'aliyun_ehpc/auth/credentials'
  require_relative 'aliyun_ehpc/auth/signature'
  require_relative 'aliyun_ehpc/models/base'
  require_relative 'aliyun_ehpc/models/cluster'
  require_relative 'aliyun_ehpc/models/job'
  require_relative 'aliyun_ehpc/models/user'
  require_relative 'aliyun_ehpc/models/queue'
  require_relative 'aliyun_ehpc/api/base'
  require_relative 'aliyun_ehpc/api/cluster'
  require_relative 'aliyun_ehpc/api/job'
  require_relative 'aliyun_ehpc/api/user'
  require_relative 'aliyun_ehpc/api/queue'
  require_relative 'aliyun_ehpc/client'
  require_relative 'aliyun_ehpc/adapters/ondemand'
  require_relative 'aliyun_ehpc/adapters/job_script_parser'
  
  class << self
    # Global configuration
    attr_accessor :configuration
    
    # Configure the gem
    #
    # @yield [Configuration] configuration object
    # @return [Configuration] the configuration object
    def configure
      # Create configuration without validation first
      self.configuration ||= Configuration.allocate
      configuration.send(:initialize_without_validation)

      # Yield for configuration
      yield(configuration) if block_given?

      # Validate after configuration
      configuration.validate!

      configuration
    end
    
    # Get current configuration
    #
    # @return [Configuration] the configuration object
    def config
      self.configuration ||= Configuration.new
    end
    
    # Create a new client instance
    #
    # @param options [Hash] client options
    # @return [Client] new client instance
    def client(options = {})
      # Use global configuration if available, otherwise create new
      config = if configuration && options.empty?
                 configuration
               else
                 # Merge global config with options
                 global_config = configuration ? configuration.to_h : {}
                 Configuration.new(global_config.merge(options))
               end

      Client.new(config)
    end
    
    # Get the gem version
    #
    # @return [String] version string
    def version
      VERSION
    end
    
    # Get the logger
    #
    # @return [Logger] logger instance
    def logger
      @logger ||= Utils::Logger.new(config.log_level)
    end
    
    # Set the logger
    #
    # @param logger [Logger] logger instance
    def logger=(logger)
      @logger = logger
    end
  end
end
