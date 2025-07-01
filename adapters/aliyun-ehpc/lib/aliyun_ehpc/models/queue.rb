# frozen_string_literal: true

module AliyunEhpc
  module Models
    # E-HPC Queue model
    class Queue < Base
      # Queue states
      STATES = %w[
        Running
        Stopped
        Draining
        Maintenance
      ].freeze
      
      # Queue types
      TYPES = %w[
        Normal
        GPU
        HighMemory
        Interactive
        Debug
      ].freeze
      
      # Define attributes
      attribute :name, type: String
      attribute :cluster_id, type: String
      attribute :description, type: String
      attribute :state, type: String, default: 'Running'
      attribute :type, type: String, default: 'Normal'
      attribute :priority, type: Integer, default: 100
      attribute :max_nodes, type: Integer
      attribute :max_cores, type: Integer
      attribute :max_memory_mb, type: Integer
      attribute :max_walltime, type: Integer
      attribute :default_walltime, type: Integer
      attribute :max_jobs_per_user, type: Integer
      attribute :max_running_jobs, type: Integer
      attribute :max_queued_jobs, type: Integer
      
      # Node configuration
      attribute :node_type, type: String
      attribute :cpu_per_node, type: Integer
      attribute :memory_per_node_mb, type: Integer
      attribute :gpu_per_node, type: Integer, default: 0
      attribute :local_storage_gb, type: Integer
      
      # Queue statistics
      attribute :total_nodes, type: Integer, default: 0
      attribute :available_nodes, type: Integer, default: 0
      attribute :allocated_nodes, type: Integer, default: 0
      attribute :down_nodes, type: Integer, default: 0
      attribute :running_jobs, type: Integer, default: 0
      attribute :queued_jobs, type: Integer, default: 0
      attribute :total_jobs, type: Integer, default: 0
      
      # Access control
      attribute :allowed_users, type: Array, default: []
      attribute :allowed_groups, type: Array, default: []
      attribute :denied_users, type: Array, default: []
      attribute :denied_groups, type: Array, default: []
      
      # Queue policies
      attribute :policies, type: Hash, default: {}
      attribute :features, type: Array, default: []
      attribute :constraints, type: Hash, default: {}
      
      # Time tracking
      attribute :create_time, type: String
      attribute :update_time, type: String
      
      # Initialize queue
      def initialize(attributes = {})
        super(attributes)
        
        # Parse time strings to Time objects if needed
        parse_time_attributes
        
        # Ensure arrays and hashes are properly initialized
        self.allowed_users ||= []
        self.allowed_groups ||= []
        self.denied_users ||= []
        self.denied_groups ||= []
        self.policies ||= {}
        self.features ||= []
        self.constraints ||= {}
      end
      
      # Check if queue is running
      #
      # @return [Boolean] true if queue is running
      def running?
        state == 'Running'
      end
      
      # Check if queue is stopped
      #
      # @return [Boolean] true if queue is stopped
      def stopped?
        state == 'Stopped'
      end
      
      # Check if queue is draining
      #
      # @return [Boolean] true if queue is draining
      def draining?
        state == 'Draining'
      end
      
      # Check if queue is in maintenance
      #
      # @return [Boolean] true if queue is in maintenance
      def maintenance?
        state == 'Maintenance'
      end
      
      # Check if queue is available for job submission
      #
      # @return [Boolean] true if queue is available
      def available?
        running? && available_nodes > 0
      end
      
      # Check if queue supports GPU jobs
      #
      # @return [Boolean] true if queue supports GPU
      def gpu_enabled?
        type == 'GPU' || (gpu_per_node && gpu_per_node > 0)
      end
      
      # Check if queue is interactive
      #
      # @return [Boolean] true if queue is interactive
      def interactive?
        type == 'Interactive'
      end
      
      # Check if queue is for debugging
      #
      # @return [Boolean] true if queue is for debugging
      def debug?
        type == 'Debug'
      end
      
      # Get queue utilization percentage
      #
      # @return [Float] utilization percentage (0.0 to 100.0)
      def utilization
        return 0.0 if total_nodes == 0
        
        (allocated_nodes.to_f / total_nodes * 100).round(2)
      end
      
      # Get queue load percentage (based on running jobs vs capacity)
      #
      # @return [Float] load percentage (0.0 to 100.0)
      def load
        return 0.0 if max_running_jobs == 0
        
        (running_jobs.to_f / max_running_jobs * 100).round(2)
      end
      
      # Get available capacity percentage
      #
      # @return [Float] available capacity percentage (0.0 to 100.0)
      def available_capacity
        return 0.0 if total_nodes == 0
        
        (available_nodes.to_f / total_nodes * 100).round(2)
      end
      
      # Get total CPU cores in queue
      #
      # @return [Integer] total CPU cores
      def total_cores
        return 0 unless total_nodes && cpu_per_node
        
        total_nodes * cpu_per_node
      end
      
      # Get available CPU cores in queue
      #
      # @return [Integer] available CPU cores
      def available_cores
        return 0 unless available_nodes && cpu_per_node
        
        available_nodes * cpu_per_node
      end
      
      # Get total memory in queue (MB)
      #
      # @return [Integer] total memory in MB
      def total_memory_mb
        return 0 unless total_nodes && memory_per_node_mb
        
        total_nodes * memory_per_node_mb
      end
      
      # Get available memory in queue (MB)
      #
      # @return [Integer] available memory in MB
      def available_memory_mb
        return 0 unless available_nodes && memory_per_node_mb
        
        available_nodes * memory_per_node_mb
      end
      
      # Get total GPUs in queue
      #
      # @return [Integer] total GPUs
      def total_gpus
        return 0 unless total_nodes && gpu_per_node
        
        total_nodes * gpu_per_node
      end
      
      # Get available GPUs in queue
      #
      # @return [Integer] available GPUs
      def available_gpus
        return 0 unless available_nodes && gpu_per_node
        
        available_nodes * gpu_per_node
      end
      
      # Check if user has access to queue
      #
      # @param user_id [String] user ID
      # @param user_groups [Array] user groups
      # @return [Boolean] true if user has access
      def user_has_access?(user_id, user_groups = [])
        # Check denied lists first
        return false if denied_users.include?(user_id)
        return false if (denied_groups & user_groups).any?
        
        # If no allowed lists are defined, allow all users
        return true if allowed_users.empty? && allowed_groups.empty?
        
        # Check allowed lists
        return true if allowed_users.include?(user_id)
        return true if (allowed_groups & user_groups).any?
        
        false
      end
      
      # Check if job can be submitted to queue
      #
      # @param job_requirements [Hash] job resource requirements
      # @return [Boolean] true if job can be submitted
      def can_accept_job?(job_requirements = {})
        return false unless available?
        
        # Check node requirements
        required_nodes = job_requirements[:nodes] || 1
        return false if max_nodes && required_nodes > max_nodes
        return false if required_nodes > available_nodes
        
        # Check CPU requirements
        required_cores = job_requirements[:cores] || 1
        return false if max_cores && required_cores > max_cores
        
        # Check memory requirements
        required_memory = job_requirements[:memory_mb] || 0
        return false if max_memory_mb && required_memory > max_memory_mb
        
        # Check walltime requirements
        required_walltime = job_requirements[:walltime] || default_walltime
        return false if max_walltime && required_walltime > max_walltime
        
        # Check GPU requirements
        required_gpus = job_requirements[:gpus] || 0
        if required_gpus > 0
          return false unless gpu_enabled?
          return false if required_gpus > available_gpus
        end
        
        # Check job limits
        return false if max_running_jobs && running_jobs >= max_running_jobs
        return false if max_queued_jobs && queued_jobs >= max_queued_jobs
        
        true
      end
      
      # Get queue statistics summary
      #
      # @return [Hash] queue statistics
      def statistics
        {
          nodes: {
            total: total_nodes,
            available: available_nodes,
            allocated: allocated_nodes,
            down: down_nodes,
            utilization: utilization
          },
          jobs: {
            running: running_jobs,
            queued: queued_jobs,
            total: total_jobs,
            load: load
          },
          resources: {
            cores: {
              total: total_cores,
              available: available_cores
            },
            memory_mb: {
              total: total_memory_mb,
              available: available_memory_mb
            },
            gpus: {
              total: total_gpus,
              available: available_gpus
            }
          }
        }
      end
      
      # Convert to SLURM partition format
      #
      # @return [Hash] SLURM partition representation
      def to_slurm_partition
        {
          partition_name: name,
          state: map_state_to_slurm,
          total_nodes: total_nodes,
          total_cpus: total_cores,
          max_time: max_walltime,
          default_time: default_walltime,
          priority_tier: priority,
          features: features.join(','),
          nodes: "#{cluster_id}-[1-#{total_nodes}]"
        }.compact
      end
      
      private
      
      # Validate queue attributes
      def validate!
        validate_queue_name(name) if name
        validate_cluster_id(cluster_id) if cluster_id
        
        if state && !STATES.include?(state)
          raise ValidationError, "Invalid queue state: #{state}. Must be one of: #{STATES.join(', ')}"
        end
        
        if type && !TYPES.include?(type)
          raise ValidationError, "Invalid queue type: #{type}. Must be one of: #{TYPES.join(', ')}"
        end
        
        validate_numeric_attributes
        validate_node_counts
        validate_job_limits
      end
      
      # Validate numeric attributes
      def validate_numeric_attributes
        numeric_attrs = %w[
          priority max_nodes max_cores max_memory_mb max_walltime default_walltime
          cpu_per_node memory_per_node_mb gpu_per_node local_storage_gb
        ]
        
        numeric_attrs.each do |attr|
          value = @attributes[attr.to_sym]
          next unless value
          
          if value <= 0
            raise ValidationError, "#{attr} must be positive"
          end
        end
      end
      
      # Validate node counts
      def validate_node_counts
        if total_nodes && available_nodes && available_nodes > total_nodes
          raise ValidationError, 'available_nodes cannot exceed total_nodes'
        end
        
        if total_nodes && allocated_nodes && allocated_nodes > total_nodes
          raise ValidationError, 'allocated_nodes cannot exceed total_nodes'
        end
        
        if total_nodes && down_nodes && down_nodes > total_nodes
          raise ValidationError, 'down_nodes cannot exceed total_nodes'
        end
      end
      
      # Validate job limits
      def validate_job_limits
        limit_attrs = %w[max_jobs_per_user max_running_jobs max_queued_jobs]
        
        limit_attrs.each do |attr|
          value = @attributes[attr.to_sym]
          next unless value
          
          if value <= 0
            raise ValidationError, "#{attr} must be positive"
          end
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
      
      # Map E-HPC queue state to SLURM state
      def map_state_to_slurm
        case state
        when 'Running' then 'UP'
        when 'Stopped' then 'DOWN'
        when 'Draining' then 'DRAIN'
        when 'Maintenance' then 'MAINT'
        else 'UNKNOWN'
        end
      end
    end
  end
end
