# frozen_string_literal: true

module AliyunEhpc
  module Models
    # E-HPC User model
    class User < Base
      # User states
      STATES = %w[
        Normal
        Locked
        Deleted
      ].freeze
      
      # User roles
      ROLES = %w[
        User
        Manager
        Admin
      ].freeze
      
      # Define attributes
      attribute :id, type: String
      attribute :name, type: String
      attribute :email, type: String
      attribute :phone, type: String
      attribute :state, type: String, default: 'Normal'
      attribute :role, type: String, default: 'User'
      attribute :group, type: String
      attribute :home_directory, type: String
      attribute :shell, type: String, default: '/bin/bash'
      attribute :uid, type: Integer
      attribute :gid, type: Integer
      attribute :create_time, type: String
      attribute :update_time, type: String
      attribute :last_login_time, type: String
      attribute :login_count, type: Integer, default: 0
      
      # Resource limits and quotas
      attribute :cpu_quota, type: Integer
      attribute :memory_quota, type: Integer
      attribute :storage_quota, type: Integer
      attribute :job_quota, type: Integer
      attribute :max_running_jobs, type: Integer, default: 10
      attribute :max_queued_jobs, type: Integer, default: 50
      
      # Usage statistics
      attribute :cpu_hours_used, type: Float, default: 0.0
      attribute :storage_used, type: Integer, default: 0
      attribute :jobs_submitted, type: Integer, default: 0
      attribute :jobs_completed, type: Integer, default: 0
      attribute :jobs_failed, type: Integer, default: 0
      
      # User preferences and settings
      attribute :preferences, type: Hash, default: {}
      attribute :environment_variables, type: Hash, default: {}
      attribute :ssh_public_keys, type: Array, default: []
      
      # Initialize user
      def initialize(attributes = {})
        super(attributes)
        
        # Parse time strings to Time objects if needed
        parse_time_attributes
        
        # Ensure arrays and hashes are properly initialized
        self.preferences ||= {}
        self.environment_variables ||= {}
        self.ssh_public_keys ||= []
      end
      
      # Check if user is active
      #
      # @return [Boolean] true if user is active
      def active?
        state == 'Normal'
      end
      
      # Check if user is locked
      #
      # @return [Boolean] true if user is locked
      def locked?
        state == 'Locked'
      end
      
      # Check if user is deleted
      #
      # @return [Boolean] true if user is deleted
      def deleted?
        state == 'Deleted'
      end
      
      # Check if user is admin
      #
      # @return [Boolean] true if user is admin
      def admin?
        role == 'Admin'
      end
      
      # Check if user is manager
      #
      # @return [Boolean] true if user is manager
      def manager?
        role == 'Manager'
      end
      
      # Check if user is regular user
      #
      # @return [Boolean] true if user is regular user
      def regular_user?
        role == 'User'
      end
      
      # Check if user has elevated privileges
      #
      # @return [Boolean] true if user has elevated privileges
      def privileged?
        admin? || manager?
      end
      
      # Get user's full name or fallback to username
      #
      # @return [String] display name
      def display_name
        name || id
      end
      
      # Get user's home directory path
      #
      # @return [String] home directory path
      def home_path
        home_directory || "/home/#{id}"
      end
      
      # Get user's default shell
      #
      # @return [String] shell path
      def default_shell
        shell || '/bin/bash'
      end
      
      # Calculate CPU quota utilization percentage
      #
      # @return [Float] CPU quota utilization percentage
      def cpu_quota_utilization
        return 0.0 unless cpu_quota && cpu_quota > 0
        return 0.0 unless cpu_hours_used
        
        (cpu_hours_used / cpu_quota * 100).round(2)
      end
      
      # Calculate storage quota utilization percentage
      #
      # @return [Float] storage quota utilization percentage
      def storage_quota_utilization
        return 0.0 unless storage_quota && storage_quota > 0
        return 0.0 unless storage_used
        
        (storage_used.to_f / storage_quota * 100).round(2)
      end
      
      # Calculate job success rate
      #
      # @return [Float] job success rate percentage
      def job_success_rate
        total_jobs = jobs_completed + jobs_failed
        return 0.0 if total_jobs == 0
        
        (jobs_completed.to_f / total_jobs * 100).round(2)
      end
      
      # Get user activity summary
      #
      # @return [Hash] user activity summary
      def activity_summary
        {
          login_count: login_count,
          last_login: last_login_time,
          jobs_submitted: jobs_submitted,
          jobs_completed: jobs_completed,
          jobs_failed: jobs_failed,
          success_rate: job_success_rate,
          cpu_hours_used: cpu_hours_used,
          storage_used: storage_used
        }
      end
      
      # Get resource usage summary
      #
      # @return [Hash] resource usage summary
      def resource_usage
        {
          cpu: {
            used: cpu_hours_used,
            quota: cpu_quota,
            utilization: cpu_quota_utilization
          },
          storage: {
            used: storage_used,
            quota: storage_quota,
            utilization: storage_quota_utilization
          },
          jobs: {
            max_running: max_running_jobs,
            max_queued: max_queued_jobs,
            quota: job_quota
          }
        }
      end
      
      # Check if user can submit more jobs
      #
      # @param current_running [Integer] current running jobs count
      # @param current_queued [Integer] current queued jobs count
      # @return [Boolean] true if user can submit more jobs
      def can_submit_job?(current_running = 0, current_queued = 0)
        return false unless active?
        
        # Check running jobs limit
        return false if max_running_jobs && current_running >= max_running_jobs
        
        # Check queued jobs limit
        return false if max_queued_jobs && current_queued >= max_queued_jobs
        
        # Check total job quota
        if job_quota
          total_jobs = current_running + current_queued
          return false if total_jobs >= job_quota
        end
        
        true
      end
      
      # Get user preference
      #
      # @param key [String, Symbol] preference key
      # @param default [Object] default value
      # @return [Object] preference value
      def preference(key, default = nil)
        preferences[key.to_s] || default
      end
      
      # Set user preference
      #
      # @param key [String, Symbol] preference key
      # @param value [Object] preference value
      def set_preference(key, value)
        self.preferences ||= {}
        preferences[key.to_s] = value
      end
      
      # Get environment variable
      #
      # @param key [String, Symbol] environment variable name
      # @param default [String] default value
      # @return [String] environment variable value
      def env_var(key, default = nil)
        environment_variables[key.to_s] || default
      end
      
      # Set environment variable
      #
      # @param key [String, Symbol] environment variable name
      # @param value [String] environment variable value
      def set_env_var(key, value)
        self.environment_variables ||= {}
        environment_variables[key.to_s] = value.to_s
      end
      
      # Add SSH public key
      #
      # @param key [String] SSH public key
      def add_ssh_key(key)
        return if key.nil? || key.empty?
        
        self.ssh_public_keys ||= []
        ssh_public_keys << key unless ssh_public_keys.include?(key)
      end
      
      # Remove SSH public key
      #
      # @param key [String] SSH public key to remove
      def remove_ssh_key(key)
        return unless ssh_public_keys
        
        ssh_public_keys.delete(key)
      end
      
      # Convert to system user format
      #
      # @return [Hash] system user representation
      def to_system_user
        {
          username: id,
          uid: uid,
          gid: gid,
          home: home_path,
          shell: default_shell,
          gecos: name || id,
          groups: [group].compact
        }
      end
      
      # Convert to LDAP user format
      #
      # @return [Hash] LDAP user representation
      def to_ldap_user
        {
          uid: id,
          cn: name || id,
          sn: name&.split(' ')&.last || id,
          givenName: name&.split(' ')&.first || id,
          mail: email,
          telephoneNumber: phone,
          homeDirectory: home_path,
          loginShell: default_shell,
          uidNumber: uid,
          gidNumber: gid,
          objectClass: %w[inetOrgPerson posixAccount]
        }.compact
      end
      
      private
      
      # Validate user attributes
      def validate!
        validate_user_id(id) if id
        
        if state && !STATES.include?(state)
          raise ValidationError, "Invalid user state: #{state}. Must be one of: #{STATES.join(', ')}"
        end
        
        if role && !ROLES.include?(role)
          raise ValidationError, "Invalid user role: #{role}. Must be one of: #{ROLES.join(', ')}"
        end
        
        if email && !email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
          raise ValidationError, 'Invalid email format'
        end
        
        if uid && uid <= 0
          raise ValidationError, 'uid must be positive'
        end
        
        if gid && gid <= 0
          raise ValidationError, 'gid must be positive'
        end
        
        validate_quotas
        validate_limits
      end
      
      # Validate quota values
      def validate_quotas
        %w[cpu_quota memory_quota storage_quota job_quota].each do |quota_attr|
          quota_value = @attributes[quota_attr.to_sym]
          next unless quota_value
          
          if quota_value <= 0
            raise ValidationError, "#{quota_attr} must be positive"
          end
        end
      end
      
      # Validate limit values
      def validate_limits
        %w[max_running_jobs max_queued_jobs].each do |limit_attr|
          limit_value = @attributes[limit_attr.to_sym]
          next unless limit_value
          
          if limit_value <= 0
            raise ValidationError, "#{limit_attr} must be positive"
          end
        end
      end
      
      # Parse time attributes from strings to Time objects
      def parse_time_attributes
        %w[create_time update_time last_login_time].each do |attr|
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
