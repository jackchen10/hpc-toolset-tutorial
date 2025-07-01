# frozen_string_literal: true

module AliyunEhpc
  # Main client class for Aliyun E-HPC API
  class Client
    attr_reader :configuration, :credentials, :auth_manager
    
    def initialize(options = {})
      # Initialize configuration
      @configuration = if options.is_a?(Configuration)
                         options
                       else
                         Configuration.new(options)
                       end
      
      # Initialize credentials
      @credentials = Auth::Credentials.from_config(@configuration)
      
      # Initialize authentication manager
      @auth_manager = Auth::Signature.new(@credentials)
      
      # Initialize logger
      @logger = Utils::Logger.new(@configuration.log_level)
      
      # Log client initialization
      @logger.info('Aliyun E-HPC client initialized', {
        type: 'client_init',
        region: @configuration.region,
        endpoint: @configuration.endpoint_url,
        api_version: @configuration.api_version
      })
    end
    
    # Get cluster API client
    #
    # @return [API::Cluster] cluster API client
    def clusters
      @clusters ||= API::Cluster.new(@auth_manager, @configuration)
    end
    
    # Get job API client
    #
    # @return [API::Job] job API client
    def jobs
      @jobs ||= API::Job.new(@auth_manager, @configuration)
    end
    
    # Get user API client
    #
    # @return [API::User] user API client
    def users
      @users ||= API::User.new(@auth_manager, @configuration)
    end
    
    # Get queue API client
    #
    # @return [API::Queue] queue API client
    def queues
      @queues ||= API::Queue.new(@auth_manager, @configuration)
    end
    
    # Test API connectivity
    #
    # @return [Boolean] true if connection is successful
    def test_connection
      begin
        clusters.list
        @logger.info('API connection test successful')
        true
      rescue StandardError => e
        @logger.error('API connection test failed', {
          error_class: e.class.name,
          error_message: e.message
        })
        false
      end
    end
    
    # Get client information
    #
    # @return [Hash] client information
    def info
      {
        gem_version: AliyunEhpc::VERSION,
        api_version: @configuration.api_version,
        region: @configuration.region,
        endpoint: @configuration.endpoint_url,
        credentials: @credentials.to_h,
        configuration: @configuration.to_h
      }
    end
    
    # Update configuration
    #
    # @param new_config [Hash] new configuration options
    # @return [self] updated client
    def configure(new_config = {})
      @configuration.update(new_config)
      
      # Reinitialize credentials if access keys changed
      if new_config.key?(:access_key_id) || new_config.key?(:access_key_secret)
        @credentials = Auth::Credentials.from_config(@configuration)
        @auth_manager = Auth::Signature.new(@credentials)
      end
      
      # Reset API clients to pick up new configuration
      @clusters = nil
      @jobs = nil
      @users = nil
      @queues = nil
      
      @logger.info('Client configuration updated')
      self
    end
    
    # Create a new client with different configuration
    #
    # @param new_config [Hash] new configuration options
    # @return [Client] new client instance
    def with_config(new_config)
      merged_config = @configuration.to_h.merge(new_config)
      self.class.new(merged_config)
    end
    
    # Execute a block with temporary configuration
    #
    # @param temp_config [Hash] temporary configuration
    # @yield [Client] client with temporary configuration
    # @return [Object] result of the block
    def with_temp_config(temp_config)
      temp_client = with_config(temp_config)
      yield temp_client
    end
    
    # Get API usage statistics
    #
    # @return [Hash] API usage statistics
    def usage_stats
      {
        clusters_api_calls: clusters.instance_variable_get(:@api_calls) || 0,
        jobs_api_calls: jobs.instance_variable_get(:@api_calls) || 0,
        users_api_calls: users.instance_variable_get(:@api_calls) || 0,
        queues_api_calls: queues.instance_variable_get(:@api_calls) || 0
      }
    end
    
    # Reset API usage statistics
    def reset_usage_stats
      [clusters, jobs, users, queues].each do |api_client|
        api_client.instance_variable_set(:@api_calls, 0)
      end
    end
    
    # Validate client configuration
    #
    # @return [Boolean] true if configuration is valid
    def valid?
      @configuration.valid? && @credentials.valid?
    end
    
    # Get validation errors
    #
    # @return [Array<String>] list of validation errors
    def validation_errors
      errors = []
      
      begin
        @configuration.validate!
      rescue ValidationError => e
        errors << "Configuration error: #{e.message}"
      end
      
      begin
        @credentials.validate!
      rescue AuthenticationError => e
        errors << "Credentials error: #{e.message}"
      end
      
      errors
    end
    
    # Create OnDemand adapter
    #
    # @param options [Hash] adapter options
    # @return [Adapters::OnDemand] OnDemand adapter instance
    def ondemand_adapter(options = {})
      adapter_config = {
        client: self,
        cluster_id: options[:cluster_id] || @configuration.cluster_id
      }.merge(options)
      
      Adapters::OnDemand.new(adapter_config)
    end
    
    # Convenience method to get default cluster
    #
    # @return [Models::Cluster, nil] default cluster or nil if not configured
    def default_cluster
      return nil unless @configuration.cluster_id
      
      clusters.describe(@configuration.cluster_id)
    rescue NotFoundError
      @logger.warn("Default cluster not found: #{@configuration.cluster_id}")
      nil
    end
    
    # Convenience method to submit a job to default cluster
    #
    # @param job_config [Hash] job configuration
    # @return [Models::Job] submitted job
    def submit_job(job_config)
      raise ConfigurationError, 'No default cluster configured' unless @configuration.cluster_id
      
      jobs.submit(@configuration.cluster_id, job_config)
    end
    
    # Convenience method to list jobs from default cluster
    #
    # @param options [Hash] query options
    # @return [Array<Models::Job>] list of jobs
    def list_jobs(options = {})
      raise ConfigurationError, 'No default cluster configured' unless @configuration.cluster_id
      
      jobs.list(@configuration.cluster_id, options)
    end
    
    # Convenience method to get job from default cluster
    #
    # @param job_id [String] job ID
    # @return [Models::Job] job object
    def get_job(job_id)
      raise ConfigurationError, 'No default cluster configured' unless @configuration.cluster_id
      
      jobs.describe(@configuration.cluster_id, job_id)
    end
    
    # Convenience method to cancel job from default cluster
    #
    # @param job_id [String] job ID
    # @return [Boolean] true if successful
    def cancel_job(job_id)
      raise ConfigurationError, 'No default cluster configured' unless @configuration.cluster_id
      
      jobs.cancel(@configuration.cluster_id, job_id)
    end
    
    # Close client and cleanup resources
    def close
      @logger.info('Aliyun E-HPC client closed')
      
      # Clear API clients
      @clusters = nil
      @jobs = nil
      @users = nil
      @queues = nil
      
      # Clear sensitive data
      @credentials = nil
      @auth_manager = nil
    end
    
    # String representation
    #
    # @return [String] string representation
    def to_s
      "#<#{self.class.name}:#{object_id} region=#{@configuration.region} endpoint=#{@configuration.endpoint_url}>"
    end
    
    # Detailed inspection
    #
    # @return [String] detailed inspection
    def inspect
      to_s
    end
  end
end
