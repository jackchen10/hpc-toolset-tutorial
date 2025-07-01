# frozen_string_literal: true

require_relative 'job_script_parser'

module AliyunEhpc
  module Adapters
    # OnDemand adapter for Aliyun E-HPC integration
    class OnDemand
      include Utils::Retry
      include Utils::Validator
      
      attr_reader :client, :cluster_id, :config, :script_parser
      
      def initialize(options = {})
        @config = options
        @client = options[:client] || AliyunEhpc.client(options)
        @cluster_id = options[:cluster_id] || @client.configuration.cluster_id
        @script_parser = JobScriptParser.new(options)
        @logger = Utils::Logger.new(@client.configuration.log_level)
        
        validate_initialization!
      end
      
      # Submit a job (OnDemand interface)
      #
      # @param script [String] job script content
      # @param after [Array<String>] job dependencies (afterok)
      # @param afterok [Array<String>] job dependencies (afterok)
      # @param afternotok [Array<String>] job dependencies (afternotok)
      # @param afterany [Array<String>] job dependencies (afterany)
      # @return [String] job ID
      def submit(script, after: [], afterok: [], afternotok: [], afterany: [])
        @logger.info('Submitting job via OnDemand adapter')
        
        # Parse SLURM script to E-HPC job configuration
        job_config = @script_parser.parse(script)
        
        # Add dependencies
        dependencies = build_dependencies(after, afterok, afternotok, afterany)
        job_config['Dependencies'] = dependencies unless dependencies.empty?
        
        # Submit job via E-HPC API
        job = @client.jobs.submit(@cluster_id, job_config)
        
        @logger.log_job_operation('submit', job.id, @cluster_id, {
          job_name: job.name,
          queue: job.queue_name,
          user: job.user_name
        })
        
        job.id
      rescue StandardError => e
        @logger.log_exception(e, {
          operation: 'submit_job',
          cluster_id: @cluster_id
        })
        raise AdapterError, "Failed to submit job: #{e.message}"
      end
      
      # Get job status (OnDemand interface)
      #
      # @param job_id [String] job ID
      # @return [Symbol] job status (:queued, :running, :completed, :suspended, :undetermined)
      def status(job_id)
        validate_job_id(job_id)
        
        job = @client.jobs.describe(@cluster_id, job_id)
        job.to_ondemand_format[:status]
      rescue NotFoundError
        :undetermined
      rescue StandardError => e
        @logger.log_exception(e, {
          operation: 'get_job_status',
          job_id: job_id,
          cluster_id: @cluster_id
        })
        :undetermined
      end
      
      # Get job info (OnDemand interface)
      #
      # @param job_id [String] job ID
      # @return [Hash] job information in OnDemand format
      def info(job_id)
        validate_job_id(job_id)
        
        job = @client.jobs.describe(@cluster_id, job_id)
        job.to_ondemand_format
      rescue NotFoundError
        { id: job_id, status: :undetermined }
      rescue StandardError => e
        @logger.log_exception(e, {
          operation: 'get_job_info',
          job_id: job_id,
          cluster_id: @cluster_id
        })
        { id: job_id, status: :undetermined }
      end
      
      # Delete/cancel a job (OnDemand interface)
      #
      # @param job_id [String] job ID
      # @return [Boolean] true if successful
      def delete(job_id)
        validate_job_id(job_id)
        
        result = @client.jobs.cancel(@cluster_id, job_id)
        
        @logger.log_job_operation('cancel', job_id, @cluster_id) if result
        
        result
      rescue StandardError => e
        @logger.log_exception(e, {
          operation: 'cancel_job',
          job_id: job_id,
          cluster_id: @cluster_id
        })
        false
      end
      
      # Hold a job (OnDemand interface)
      #
      # @param job_id [String] job ID
      # @return [Boolean] true if successful
      def hold(job_id)
        validate_job_id(job_id)
        
        result = @client.jobs.hold(@cluster_id, job_id)
        
        @logger.log_job_operation('hold', job_id, @cluster_id) if result
        
        result
      rescue StandardError => e
        @logger.log_exception(e, {
          operation: 'hold_job',
          job_id: job_id,
          cluster_id: @cluster_id
        })
        false
      end
      
      # Release a held job (OnDemand interface)
      #
      # @param job_id [String] job ID
      # @return [Boolean] true if successful
      def release(job_id)
        validate_job_id(job_id)
        
        result = @client.jobs.release(@cluster_id, job_id)
        
        @logger.log_job_operation('release', job_id, @cluster_id) if result
        
        result
      rescue StandardError => e
        @logger.log_exception(e, {
          operation: 'release_job',
          job_id: job_id,
          cluster_id: @cluster_id
        })
        false
      end
      
      # Get cluster info (OnDemand interface)
      #
      # @return [Hash] cluster information
      def cluster_info
        cluster = @client.clusters.describe(@cluster_id)
        
        {
          name: cluster.name,
          state: cluster.state,
          nodes: cluster.total_nodes,
          running_nodes: cluster.running_node_count,
          queues: cluster.queues.map(&:name)
        }
      rescue StandardError => e
        @logger.log_exception(e, {
          operation: 'get_cluster_info',
          cluster_id: @cluster_id
        })
        { name: @cluster_id, state: 'Unknown' }
      end
      
      # Get queue info (OnDemand interface)
      #
      # @return [Array<Hash>] list of queues
      def queue_info
        queues = @client.queues.list(@cluster_id)
        
        queues.map do |queue|
          {
            name: queue.name,
            state: queue.state,
            nodes: queue.total_nodes,
            running_jobs: queue.running_jobs,
            queued_jobs: queue.queued_jobs
          }
        end
      rescue StandardError => e
        @logger.log_exception(e, {
          operation: 'get_queue_info',
          cluster_id: @cluster_id
        })
        []
      end
      
      # Get node info (OnDemand interface)
      #
      # @return [Array<Hash>] list of nodes
      def node_info
        nodes = @client.clusters.nodes(@cluster_id)
        
        nodes.map do |node|
          {
            name: node['HostName'] || node['InstanceId'],
            state: node['Status'] || 'Unknown',
            cores: node['Cores'] || 0,
            memory: node['Memory'] || 0,
            features: node['Features'] || []
          }
        end
      rescue StandardError => e
        @logger.log_exception(e, {
          operation: 'get_node_info',
          cluster_id: @cluster_id
        })
        []
      end
      
      # Get job output (OnDemand interface)
      #
      # @param job_id [String] job ID
      # @return [Hash] job output
      def job_output(job_id)
        validate_job_id(job_id)
        
        @client.jobs.output(@cluster_id, job_id)
      rescue StandardError => e
        @logger.log_exception(e, {
          operation: 'get_job_output',
          job_id: job_id,
          cluster_id: @cluster_id
        })
        { stdout: '', stderr: '', log_info: {} }
      end
      
      # List jobs (OnDemand interface)
      #
      # @param options [Hash] query options
      # @return [Array<Hash>] list of jobs in OnDemand format
      def jobs(options = {})
        jobs_list = @client.jobs.list(@cluster_id, options)
        
        jobs_list.map(&:to_ondemand_format)
      rescue StandardError => e
        @logger.log_exception(e, {
          operation: 'list_jobs',
          cluster_id: @cluster_id
        })
        []
      end
      
      # Test adapter connectivity
      #
      # @return [Boolean] true if connection is successful
      def test_connection
        @client.test_connection && !@client.clusters.describe(@cluster_id).nil?
      rescue StandardError
        false
      end
      
      # Get adapter configuration
      #
      # @return [Hash] adapter configuration
      def adapter_config
        {
          cluster_id: @cluster_id,
          client_info: @client.info,
          script_parser_config: @script_parser.config
        }
      end
      
      # Convert to OnDemand cluster configuration
      #
      # @return [Hash] OnDemand cluster configuration
      def to_ondemand_cluster_config
        cluster = @client.clusters.describe(@cluster_id)
        cluster.to_ondemand_config
      rescue StandardError => e
        @logger.log_exception(e, {
          operation: 'generate_ondemand_config',
          cluster_id: @cluster_id
        })
        
        # Fallback configuration
        {
          v2: {
            metadata: {
              title: @cluster_id,
              description: 'Aliyun E-HPC Cluster'
            },
            login: {
              host: 'localhost'
            },
            job: {
              adapter: 'aliyun_ehpc',
              cluster: @cluster_id,
              bin: '/usr/bin'
            },
            custom: {
              aliyun_ehpc: {
                cluster_id: @cluster_id,
                region: @client.configuration.region
              }
            }
          }
        }
      end
      
      private
      
      # Validate adapter initialization
      def validate_initialization!
        raise AdapterError, 'Client is required' unless @client
        raise AdapterError, 'Cluster ID is required' unless @cluster_id
        
        validate_cluster_id(@cluster_id)
      end
      
      # Build job dependencies array
      #
      # @param after [Array<String>] after dependencies
      # @param afterok [Array<String>] afterok dependencies
      # @param afternotok [Array<String>] afternotok dependencies
      # @param afterany [Array<String>] afterany dependencies
      # @return [Array<String>] formatted dependencies
      def build_dependencies(after, afterok, afternotok, afterany)
        dependencies = []
        
        # Add after dependencies (same as afterok)
        (after + afterok).each do |job_id|
          dependencies << "afterok:#{job_id}"
        end
        
        # Add afternotok dependencies
        afternotok.each do |job_id|
          dependencies << "afternotok:#{job_id}"
        end
        
        # Add afterany dependencies
        afterany.each do |job_id|
          dependencies << "afterany:#{job_id}"
        end
        
        dependencies
      end
    end
  end
end
