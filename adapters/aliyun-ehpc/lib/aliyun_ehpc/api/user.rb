# frozen_string_literal: true

module AliyunEhpc
  module API
    # User management API client
    class User < Base
      # List all users
      #
      # @param cluster_id [String] cluster ID
      # @param options [Hash] query options
      # @return [Array<Models::User>] list of users
      def list(cluster_id, options = {})
        validate_cluster_id(cluster_id)
        validate_list_params(options)
        
        params = build_list_params(cluster_id, options)
        response = get('ListUsers', params)
        
        users_data = response['Users'] || []
        users_data.map { |user_data| Models::User.new(user_data) }
      end
      
      # Get user details
      #
      # @param cluster_id [String] cluster ID
      # @param user_id [String] user ID
      # @return [Models::User] user object
      def describe(cluster_id, user_id)
        validate_cluster_id(cluster_id)
        validate_user_id(user_id)
        
        params = {
          'ClusterId' => cluster_id,
          'UserId' => user_id
        }
        
        response = get('GetUserImage', params)
        user_data = response['UserInfo'] || response
        
        Models::User.new(user_data)
      end
      
      # Create a new user
      #
      # @param cluster_id [String] cluster ID
      # @param user_config [Hash] user configuration
      # @return [Models::User] created user object
      def create(cluster_id, user_config)
        validate_cluster_id(cluster_id)
        validate_create_params(user_config)
        
        params = build_create_params(cluster_id, user_config)
        response = post('AddUser', params)
        
        # Return the created user
        describe(cluster_id, user_config['Name'])
      end
      
      # Update user information
      #
      # @param cluster_id [String] cluster ID
      # @param user_id [String] user ID
      # @param user_config [Hash] user configuration updates
      # @return [Models::User] updated user object
      def update(cluster_id, user_id, user_config)
        validate_cluster_id(cluster_id)
        validate_user_id(user_id)
        validate_update_params(user_config)
        
        params = build_update_params(cluster_id, user_id, user_config)
        response = post('ModifyUser', params)
        
        # Return the updated user
        describe(cluster_id, user_id)
      end
      
      # Delete a user
      #
      # @param cluster_id [String] cluster ID
      # @param user_id [String] user ID
      # @return [Boolean] true if successful
      def delete(cluster_id, user_id)
        validate_cluster_id(cluster_id)
        validate_user_id(user_id)
        
        params = {
          'ClusterId' => cluster_id,
          'User.1.Name' => user_id
        }
        
        response = post('DeleteUsers', params)
        response['RequestId'] ? true : false
      end
      
      # Reset user password
      #
      # @param cluster_id [String] cluster ID
      # @param user_id [String] user ID
      # @param new_password [String] new password
      # @return [Boolean] true if successful
      def reset_password(cluster_id, user_id, new_password)
        validate_cluster_id(cluster_id)
        validate_user_id(user_id)
        validate_password(new_password)
        
        params = {
          'ClusterId' => cluster_id,
          'User.1.Name' => user_id,
          'User.1.Password' => new_password
        }
        
        response = post('ResetUserPassword', params)
        response['RequestId'] ? true : false
      end
      
      # Get user jobs
      #
      # @param cluster_id [String] cluster ID
      # @param user_id [String] user ID
      # @param options [Hash] query options
      # @return [Array<Models::Job>] list of user jobs
      def jobs(cluster_id, user_id, options = {})
        validate_cluster_id(cluster_id)
        validate_user_id(user_id)
        
        # Use the job API to list jobs for this user
        job_api = Job.new(@auth, @config)
        job_api.list(cluster_id, options.merge(owner: user_id))
      end
      
      # Get user quota information
      #
      # @param cluster_id [String] cluster ID
      # @param user_id [String] user ID
      # @return [Hash] user quota information
      def quota(cluster_id, user_id)
        validate_cluster_id(cluster_id)
        validate_user_id(user_id)
        
        params = {
          'ClusterId' => cluster_id,
          'UserId' => user_id
        }
        
        response = get('GetUserQuota', params)
        response['QuotaInfo'] || {}
      end
      
      # Set user quota
      #
      # @param cluster_id [String] cluster ID
      # @param user_id [String] user ID
      # @param quota_config [Hash] quota configuration
      # @return [Boolean] true if successful
      def set_quota(cluster_id, user_id, quota_config)
        validate_cluster_id(cluster_id)
        validate_user_id(user_id)
        validate_quota_params(quota_config)
        
        params = build_quota_params(cluster_id, user_id, quota_config)
        response = post('SetUserQuota', params)
        response['RequestId'] ? true : false
      end
      
      # Get user usage statistics
      #
      # @param cluster_id [String] cluster ID
      # @param user_id [String] user ID
      # @param options [Hash] query options
      # @return [Hash] user usage statistics
      def usage(cluster_id, user_id, options = {})
        validate_cluster_id(cluster_id)
        validate_user_id(user_id)
        
        params = {
          'ClusterId' => cluster_id,
          'UserId' => user_id,
          'StartTime' => options[:start_time] || (Time.now - 30 * 24 * 3600).iso8601,
          'EndTime' => options[:end_time] || Time.now.iso8601
        }
        
        response = get('GetUserUsage', params)
        response['UsageInfo'] || {}
      end
      
      # Add SSH key for user
      #
      # @param cluster_id [String] cluster ID
      # @param user_id [String] user ID
      # @param ssh_key [String] SSH public key
      # @return [Boolean] true if successful
      def add_ssh_key(cluster_id, user_id, ssh_key)
        validate_cluster_id(cluster_id)
        validate_user_id(user_id)
        validate_ssh_key(ssh_key)
        
        params = {
          'ClusterId' => cluster_id,
          'UserId' => user_id,
          'PublicKey' => ssh_key
        }
        
        response = post('AddUserSSHKey', params)
        response['RequestId'] ? true : false
      end
      
      # Remove SSH key for user
      #
      # @param cluster_id [String] cluster ID
      # @param user_id [String] user ID
      # @param ssh_key [String] SSH public key to remove
      # @return [Boolean] true if successful
      def remove_ssh_key(cluster_id, user_id, ssh_key)
        validate_cluster_id(cluster_id)
        validate_user_id(user_id)
        validate_ssh_key(ssh_key)
        
        params = {
          'ClusterId' => cluster_id,
          'UserId' => user_id,
          'PublicKey' => ssh_key
        }
        
        response = post('RemoveUserSSHKey', params)
        response['RequestId'] ? true : false
      end
      
      # List user SSH keys
      #
      # @param cluster_id [String] cluster ID
      # @param user_id [String] user ID
      # @return [Array<String>] list of SSH public keys
      def ssh_keys(cluster_id, user_id)
        validate_cluster_id(cluster_id)
        validate_user_id(user_id)
        
        params = {
          'ClusterId' => cluster_id,
          'UserId' => user_id
        }
        
        response = get('ListUserSSHKeys', params)
        response['SSHKeys'] || []
      end
      
      # Set user environment variables
      #
      # @param cluster_id [String] cluster ID
      # @param user_id [String] user ID
      # @param env_vars [Hash] environment variables
      # @return [Boolean] true if successful
      def set_environment(cluster_id, user_id, env_vars)
        validate_cluster_id(cluster_id)
        validate_user_id(user_id)
        
        params = {
          'ClusterId' => cluster_id,
          'UserId' => user_id
        }
        
        env_vars.each_with_index do |(key, value), index|
          params["EnvVar.#{index + 1}.Name"] = key
          params["EnvVar.#{index + 1}.Value"] = value
        end
        
        response = post('SetUserEnvironment', params)
        response['RequestId'] ? true : false
      end
      
      private
      
      # Validate list parameters
      def validate_list_params(options)
        if options[:page_size]
          validate_numeric_params({ page_size: options[:page_size] }, { page_size: { min: 1, max: 100 } })
        end
        
        if options[:page_number]
          validate_numeric_params({ page_number: options[:page_number] }, { page_number: { min: 1 } })
        end
      end
      
      # Validate user creation parameters
      def validate_create_params(config)
        required_keys = %w[Name Password]
        validate_required_params(config, required_keys)
        
        validate_string_params(config, {
          'Name' => { min_length: 1, max_length: 32, pattern: /^[a-zA-Z0-9._-]+$/ },
          'Group' => { max_length: 32, pattern: /^[a-zA-Z0-9._-]+$/ }
        })
        
        validate_password(config['Password'])
      end
      
      # Validate user update parameters
      def validate_update_params(config)
        if config['Password']
          validate_password(config['Password'])
        end
        
        if config['Group']
          validate_string_params(config, {
            'Group' => { max_length: 32, pattern: /^[a-zA-Z0-9._-]+$/ }
          })
        end
      end
      
      # Validate quota parameters
      def validate_quota_params(config)
        validate_numeric_params(config, {
          'CpuQuota' => { min: 0 },
          'MemoryQuota' => { min: 0 },
          'StorageQuota' => { min: 0 },
          'JobQuota' => { min: 0 },
          'MaxRunningJobs' => { min: 1 },
          'MaxQueuedJobs' => { min: 1 }
        })
      end
      
      # Validate password
      def validate_password(password)
        unless password.is_a?(String) && password.length >= 8
          raise ValidationError, 'Password must be at least 8 characters long'
        end
        
        unless password.match?(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
          raise ValidationError, 'Password must contain at least one lowercase letter, one uppercase letter, and one digit'
        end
      end
      
      # Validate SSH key
      def validate_ssh_key(ssh_key)
        unless ssh_key.is_a?(String) && !ssh_key.empty?
          raise ValidationError, 'SSH key must be a non-empty string'
        end
        
        unless ssh_key.match?(/^ssh-(rsa|dss|ed25519|ecdsa) /)
          raise ValidationError, 'Invalid SSH key format'
        end
      end
      
      # Build user creation parameters
      def build_create_params(cluster_id, config)
        params = {
          'ClusterId' => cluster_id,
          'User.1.Name' => config['Name'],
          'User.1.Password' => config['Password']
        }
        
        params['User.1.Group'] = config['Group'] if config['Group']
        
        params
      end
      
      # Build user update parameters
      def build_update_params(cluster_id, user_id, config)
        params = {
          'ClusterId' => cluster_id,
          'User.1.Name' => user_id
        }
        
        params['User.1.Password'] = config['Password'] if config['Password']
        params['User.1.Group'] = config['Group'] if config['Group']
        
        params
      end
      
      # Build list parameters
      def build_list_params(cluster_id, options)
        params = { 'ClusterId' => cluster_id }
        
        params['PageSize'] = options[:page_size] if options[:page_size]
        params['PageNumber'] = options[:page_number] if options[:page_number]
        
        params
      end
      
      # Build quota parameters
      def build_quota_params(cluster_id, user_id, config)
        params = {
          'ClusterId' => cluster_id,
          'UserId' => user_id
        }
        
        params['CpuQuota'] = config['CpuQuota'] if config['CpuQuota']
        params['MemoryQuota'] = config['MemoryQuota'] if config['MemoryQuota']
        params['StorageQuota'] = config['StorageQuota'] if config['StorageQuota']
        params['JobQuota'] = config['JobQuota'] if config['JobQuota']
        params['MaxRunningJobs'] = config['MaxRunningJobs'] if config['MaxRunningJobs']
        params['MaxQueuedJobs'] = config['MaxQueuedJobs'] if config['MaxQueuedJobs']
        
        params
      end
    end
  end
end
