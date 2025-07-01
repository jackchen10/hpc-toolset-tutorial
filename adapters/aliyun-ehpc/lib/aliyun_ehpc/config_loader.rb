# frozen_string_literal: true

require 'yaml'
require 'erb'

module AliyunEhpc
  # Configuration loader for credentials and settings
  class ConfigLoader
    attr_reader :environment, :config_path
    
    def initialize(environment = nil, config_path = nil)
      @environment = environment || detect_environment
      @config_path = config_path || default_config_path
    end
    
    # Load configuration from file
    #
    # @return [Hash] configuration hash
    def load_config
      return {} unless File.exist?(@config_path)
      
      # Load and parse YAML with ERB
      yaml_content = File.read(@config_path)
      erb_content = ERB.new(yaml_content).result
      config_data = YAML.load(erb_content)
      
      # Return environment-specific configuration
      config_data[@environment] || {}
    rescue StandardError => e
      puts "Warning: Failed to load configuration from #{@config_path}: #{e.message}"
      {}
    end
    
    # Load credentials specifically
    #
    # @return [Hash] credentials hash
    def load_credentials
      config = load_config
      {
        access_key_id: config['access_key_id'],
        access_key_secret: config['access_key_secret'],
        region: config['region'],
        endpoint: config['endpoint'],
        timeout: config['timeout'],
        retry_count: config['retry_count'],
        log_level: config['log_level']&.to_sym
      }.compact
    end
    
    # Check if configuration file exists
    #
    # @return [Boolean] true if config file exists
    def config_exists?
      File.exist?(@config_path)
    end
    
    # Get available environments
    #
    # @return [Array<String>] list of environments
    def available_environments
      return [] unless config_exists?
      
      yaml_content = File.read(@config_path)
      erb_content = ERB.new(yaml_content).result
      config_data = YAML.safe_load(erb_content)
      
      config_data.keys
    rescue StandardError
      []
    end
    
    private
    
    # Detect current environment
    #
    # @return [String] environment name
    def detect_environment
      ENV['RAILS_ENV'] || ENV['RACK_ENV'] || ENV['ALIYUN_EHPC_ENV'] || 'development'
    end
    
    # Get default configuration file path
    #
    # @return [String] config file path
    def default_config_path
      File.join(File.dirname(__FILE__), '..', '..', 'config', 'credentials.yml')
    end
  end
end
