# frozen_string_literal: true

module AliyunEhpc
  module Models
    # E-HPC Cluster model
    class Cluster < Base
      # Cluster states
      STATES = %w[
        Creating
        Running
        Stopping
        Stopped
        Exception
        Releasing
        Released
      ].freeze
      
      # Cluster types
      TYPES = %w[
        OnDemand
        Subscription
      ].freeze
      
      # Define attributes
      attribute :id, type: String
      attribute :name, type: String
      attribute :description, type: String
      attribute :state, type: String
      attribute :type, type: String
      attribute :region, type: String
      attribute :zone, type: String
      attribute :vpc_id, type: String
      attribute :subnet_id, type: String
      attribute :security_group_id, type: String
      attribute :create_time, type: String
      attribute :update_time, type: String
      attribute :node_count, type: Integer, default: 0
      attribute :running_node_count, type: Integer, default: 0
      attribute :max_node_count, type: Integer, default: 100
      attribute :login_nodes, type: Array, default: []
      attribute :compute_nodes, type: Array, default: []
      attribute :manager_nodes, type: Array, default: []
      attribute :scheduler_type, type: String, default: 'SLURM'
      attribute :os_tag, type: String
      attribute :account_type, type: String
      attribute :client_version, type: String
      
      # Cluster configuration attributes
      attribute :auto_scaling, type: Hash, default: {}
      attribute :network_config, type: Hash, default: {}
      attribute :storage_config, type: Hash, default: {}
      attribute :software_config, type: Hash, default: {}
      
      # Initialize cluster
      def initialize(attributes = {})
        super(attributes)
        
        # Parse time strings to Time objects if needed
        parse_time_attributes
        
        # Ensure arrays are properly initialized
        self.login_nodes ||= []
        self.compute_nodes ||= []
        self.manager_nodes ||= []
      end
      
      # Check if cluster is running
      #
      # @return [Boolean] true if cluster is running
      def running?
        state == 'Running'
      end
      
      # Check if cluster is stopped
      #
      # @return [Boolean] true if cluster is stopped
      def stopped?
        state == 'Stopped'
      end
      
      # Check if cluster is creating
      #
      # @return [Boolean] true if cluster is creating
      def creating?
        state == 'Creating'
      end
      
      # Check if cluster is in exception state
      #
      # @return [Boolean] true if cluster has exception
      def exception?
        state == 'Exception'
      end
      
      # Check if cluster is being released
      #
      # @return [Boolean] true if cluster is being released
      def releasing?
        state == 'Releasing'
      end
      
      # Check if cluster is released
      #
      # @return [Boolean] true if cluster is released
      def released?
        state == 'Released'
      end
      
      # Check if cluster is available for job submission
      #
      # @return [Boolean] true if cluster is available
      def available?
        running? && running_node_count > 0
      end
      
      # Get total node count
      #
      # @return [Integer] total node count
      def total_nodes
        login_nodes.size + compute_nodes.size + manager_nodes.size
      end
      
      # Get compute node count
      #
      # @return [Integer] compute node count
      def compute_node_count
        compute_nodes.size
      end
      
      # Get login node count
      #
      # @return [Integer] login node count
      def login_node_count
        login_nodes.size
      end
      
      # Get manager node count
      #
      # @return [Integer] manager node count
      def manager_node_count
        manager_nodes.size
      end
      
      # Get cluster utilization percentage
      #
      # @return [Float] utilization percentage (0.0 to 100.0)
      def utilization
        return 0.0 if max_node_count == 0
        
        (running_node_count.to_f / max_node_count * 100).round(2)
      end
      
      # Check if auto scaling is enabled
      #
      # @return [Boolean] true if auto scaling is enabled
      def auto_scaling_enabled?
        auto_scaling['enabled'] == true
      end
      
      # Get auto scaling configuration
      #
      # @return [Hash] auto scaling configuration
      def auto_scaling_config
        auto_scaling || {}
      end
      
      # Get network configuration
      #
      # @return [Hash] network configuration
      def network_configuration
        network_config || {}
      end
      
      # Get storage configuration
      #
      # @return [Hash] storage configuration
      def storage_configuration
        storage_config || {}
      end
      
      # Get software configuration
      #
      # @return [Hash] software configuration
      def software_configuration
        software_config || {}
      end
      
      # Get cluster age in seconds
      #
      # @return [Integer] cluster age in seconds
      def age
        return 0 unless create_time
        
        created_at = Time.parse(create_time)
        Time.now - created_at
      rescue ArgumentError
        0
      end
      
      # Get cluster age in human readable format
      #
      # @return [String] human readable age
      def age_human
        seconds = age
        return '0 seconds' if seconds == 0
        
        days = seconds / 86400
        hours = (seconds % 86400) / 3600
        minutes = (seconds % 3600) / 60
        
        parts = []
        parts << "#{days.to_i} days" if days >= 1
        parts << "#{hours.to_i} hours" if hours >= 1
        parts << "#{minutes.to_i} minutes" if minutes >= 1 && days < 1
        
        parts.empty? ? 'less than a minute' : parts.join(', ')
      end
      
      # Convert to OnDemand cluster configuration
      #
      # @return [Hash] OnDemand cluster configuration
      def to_ondemand_config
        {
          v2: {
            metadata: {
              title: name || id,
              description: description
            },
            login: {
              host: login_nodes.first&.dig('PublicIpAddress') || 'localhost'
            },
            job: {
              adapter: 'aliyun_ehpc',
              cluster: id,
              bin: '/usr/bin',
              conf: '/etc/slurm/slurm.conf'
            },
            custom: {
              aliyun_ehpc: {
                cluster_id: id,
                region: region,
                zone: zone
              }
            }
          }
        }
      end
      
      private
      
      # Validate cluster attributes
      def validate!
        validate_cluster_id(id) if id
        
        if state && !STATES.include?(state)
          raise ValidationError, "Invalid cluster state: #{state}. Must be one of: #{STATES.join(', ')}"
        end
        
        if type && !TYPES.include?(type)
          raise ValidationError, "Invalid cluster type: #{type}. Must be one of: #{TYPES.join(', ')}"
        end
        
        if node_count && node_count < 0
          raise ValidationError, 'node_count must be non-negative'
        end
        
        if running_node_count && running_node_count < 0
          raise ValidationError, 'running_node_count must be non-negative'
        end
        
        if max_node_count && max_node_count < 1
          raise ValidationError, 'max_node_count must be positive'
        end
        
        if running_node_count && node_count && running_node_count > node_count
          raise ValidationError, 'running_node_count cannot exceed node_count'
        end
      end
      
      # Parse time attributes from strings to Time objects
      def parse_time_attributes
        %w[create_time update_time].each do |attr|
          time_value = @attributes[attr.to_sym]
          next unless time_value.is_a?(String)
          
          begin
            @attributes[attr.to_sym] = Time.parse(time_value)
          rescue ArgumentError
            # Keep original string if parsing fails
          end
        end
      end
    end
  end
end
