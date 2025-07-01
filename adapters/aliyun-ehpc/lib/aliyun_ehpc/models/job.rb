# frozen_string_literal: true

module AliyunEhpc
  module Models
    # E-HPC Job model
    class Job < Base
      # Job states
      STATES = %w[
        Queued
        Running
        Completed
        Failed
        Cancelled
        Suspended
        Timeout
      ].freeze
      
      # Job priorities
      PRIORITIES = %w[
        Low
        Normal
        High
        Urgent
      ].freeze
      
      # Define attributes
      attribute :id, type: String
      attribute :name, type: String
      attribute :cluster_id, type: String
      attribute :queue_name, type: String
      attribute :user_name, type: String
      attribute :state, type: String
      attribute :priority, type: String, default: 'Normal'
      attribute :command, type: String
      attribute :working_directory, type: String
      attribute :stdout_path, type: String
      attribute :stderr_path, type: String
      attribute :environment, type: Hash, default: {}
      attribute :resources, type: Hash, default: {}
      attribute :submit_time, type: String
      attribute :start_time, type: String
      attribute :end_time, type: String
      attribute :walltime_limit, type: Integer
      attribute :walltime_used, type: Integer
      attribute :exit_code, type: Integer
      attribute :node_list, type: Array, default: []
      attribute :cpu_count, type: Integer
      attribute :memory_mb, type: Integer
      attribute :gpu_count, type: Integer, default: 0
      
      # Job script and configuration
      attribute :script_content, type: String
      attribute :script_path, type: String
      attribute :job_array_spec, type: String
      attribute :dependency_list, type: Array, default: []
      
      # Runtime information
      attribute :runtime_info, type: Hash, default: {}
      attribute :error_info, type: Hash, default: {}
      
      # Initialize job
      def initialize(attributes = {})
        super(attributes)
        
        # Parse time strings to Time objects if needed
        parse_time_attributes
        
        # Ensure arrays are properly initialized
        self.node_list ||= []
        self.dependency_list ||= []
        self.environment ||= {}
        self.resources ||= {}
      end
      
      # Check if job is queued
      #
      # @return [Boolean] true if job is queued
      def queued?
        state == 'Queued'
      end
      
      # Check if job is running
      #
      # @return [Boolean] true if job is running
      def running?
        state == 'Running'
      end
      
      # Check if job is completed
      #
      # @return [Boolean] true if job is completed
      def completed?
        state == 'Completed'
      end
      
      # Check if job failed
      #
      # @return [Boolean] true if job failed
      def failed?
        state == 'Failed'
      end
      
      # Check if job was cancelled
      #
      # @return [Boolean] true if job was cancelled
      def cancelled?
        state == 'Cancelled'
      end
      
      # Check if job is suspended
      #
      # @return [Boolean] true if job is suspended
      def suspended?
        state == 'Suspended'
      end
      
      # Check if job timed out
      #
      # @return [Boolean] true if job timed out
      def timeout?
        state == 'Timeout'
      end
      
      # Check if job is finished (completed, failed, cancelled, or timeout)
      #
      # @return [Boolean] true if job is finished
      def finished?
        %w[Completed Failed Cancelled Timeout].include?(state)
      end
      
      # Check if job is active (queued, running, or suspended)
      #
      # @return [Boolean] true if job is active
      def active?
        %w[Queued Running Suspended].include?(state)
      end
      
      # Check if job was successful
      #
      # @return [Boolean] true if job was successful
      def successful?
        completed? && (exit_code.nil? || exit_code == 0)
      end
      
      # Get job duration in seconds
      #
      # @return [Integer] job duration in seconds
      def duration
        return 0 unless start_time
        
        end_time_obj = end_time ? Time.parse(end_time) : Time.now
        start_time_obj = Time.parse(start_time)
        
        (end_time_obj - start_time_obj).to_i
      rescue ArgumentError
        0
      end
      
      # Get job duration in human readable format
      #
      # @return [String] human readable duration
      def duration_human
        seconds = duration
        return '0 seconds' if seconds == 0
        
        hours = seconds / 3600
        minutes = (seconds % 3600) / 60
        secs = seconds % 60
        
        if hours > 0
          "#{hours}h #{minutes}m #{secs}s"
        elsif minutes > 0
          "#{minutes}m #{secs}s"
        else
          "#{secs}s"
        end
      end
      
      # Get queue time in seconds
      #
      # @return [Integer] queue time in seconds
      def queue_time
        return 0 unless submit_time && start_time
        
        start_time_obj = Time.parse(start_time)
        submit_time_obj = Time.parse(submit_time)
        
        (start_time_obj - submit_time_obj).to_i
      rescue ArgumentError
        0
      end
      
      # Get walltime efficiency percentage
      #
      # @return [Float] walltime efficiency percentage
      def walltime_efficiency
        return 0.0 unless walltime_limit && walltime_limit > 0
        return 0.0 unless walltime_used
        
        (walltime_used.to_f / walltime_limit * 100).round(2)
      end
      
      # Get resource allocation summary
      #
      # @return [Hash] resource allocation summary
      def resource_summary
        {
          nodes: node_list.size,
          cpus: cpu_count || 0,
          memory_mb: memory_mb || 0,
          gpus: gpu_count || 0,
          walltime_limit: walltime_limit,
          walltime_used: walltime_used
        }
      end
      
      # Get job progress percentage (for running jobs)
      #
      # @return [Float] progress percentage (0.0 to 100.0)
      def progress
        return 100.0 if finished?
        return 0.0 unless running? && walltime_limit && walltime_limit > 0
        
        elapsed = duration
        return 0.0 if elapsed <= 0
        
        progress_pct = (elapsed.to_f / walltime_limit * 100).round(2)
        [progress_pct, 100.0].min
      end
      
      # Get estimated completion time
      #
      # @return [Time, nil] estimated completion time
      def estimated_completion_time
        return nil unless running? && walltime_limit && start_time
        
        start_time_obj = Time.parse(start_time)
        start_time_obj + walltime_limit
      rescue ArgumentError
        nil
      end
      
      # Convert to SLURM job format
      #
      # @return [Hash] SLURM job representation
      def to_slurm_format
        {
          job_id: id,
          job_name: name,
          user_name: user_name,
          partition: queue_name,
          state: map_state_to_slurm,
          nodes: node_list.size,
          cpus: cpu_count,
          submit_time: submit_time,
          start_time: start_time,
          end_time: end_time,
          time_limit: walltime_limit,
          work_dir: working_directory,
          std_out: stdout_path,
          std_err: stderr_path,
          exit_code: exit_code
        }.compact
      end
      
      # Convert to OnDemand job format
      #
      # @return [Hash] OnDemand job representation
      def to_ondemand_format
        {
          id: id,
          status: map_state_to_ondemand,
          job_name: name,
          job_owner: user_name,
          accounting_id: user_name,
          procs: cpu_count,
          queue_name: queue_name,
          wallclock_time: walltime_used,
          wallclock_limit: walltime_limit,
          submit_time: submit_time,
          dispatch_time: start_time,
          native: {
            cluster_id: cluster_id,
            node_list: node_list,
            memory_mb: memory_mb,
            gpu_count: gpu_count
          }
        }.compact
      end
      
      private
      
      # Validate job attributes
      def validate!
        validate_job_id(id) if id
        validate_cluster_id(cluster_id) if cluster_id
        validate_queue_name(queue_name) if queue_name
        validate_user_id(user_name) if user_name
        
        if state && !STATES.include?(state)
          raise ValidationError, "Invalid job state: #{state}. Must be one of: #{STATES.join(', ')}"
        end
        
        if priority && !PRIORITIES.include?(priority)
          raise ValidationError, "Invalid job priority: #{priority}. Must be one of: #{PRIORITIES.join(', ')}"
        end
        
        if walltime_limit && walltime_limit <= 0
          raise ValidationError, 'walltime_limit must be positive'
        end
        
        if walltime_used && walltime_used < 0
          raise ValidationError, 'walltime_used must be non-negative'
        end
        
        if cpu_count && cpu_count <= 0
          raise ValidationError, 'cpu_count must be positive'
        end
        
        if memory_mb && memory_mb <= 0
          raise ValidationError, 'memory_mb must be positive'
        end
        
        if gpu_count && gpu_count < 0
          raise ValidationError, 'gpu_count must be non-negative'
        end
      end
      
      # Parse time attributes from strings to Time objects
      def parse_time_attributes
        %w[submit_time start_time end_time].each do |attr|
          time_value = @attributes[attr.to_sym]
          next unless time_value.is_a?(String)
          
          begin
            @attributes[attr.to_sym] = Time.parse(time_value)
          rescue ArgumentError
            # Keep original string if parsing fails
          end
        end
      end
      
      # Map E-HPC job state to SLURM state
      def map_state_to_slurm
        case state
        when 'Queued' then 'PENDING'
        when 'Running' then 'RUNNING'
        when 'Completed' then 'COMPLETED'
        when 'Failed' then 'FAILED'
        when 'Cancelled' then 'CANCELLED'
        when 'Suspended' then 'SUSPENDED'
        when 'Timeout' then 'TIMEOUT'
        else 'UNKNOWN'
        end
      end
      
      # Map E-HPC job state to OnDemand state
      def map_state_to_ondemand
        case state
        when 'Queued' then :queued
        when 'Running' then :running
        when 'Completed' then :completed
        when 'Failed' then :completed
        when 'Cancelled' then :completed
        when 'Suspended' then :suspended
        when 'Timeout' then :completed
        else :undetermined
        end
      end
    end
  end
end
