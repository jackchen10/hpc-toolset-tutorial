# frozen_string_literal: true

module AliyunEhpc
  module API
    # Queue management API client
    class Queue < Base
      # List all queues
      #
      # @param cluster_id [String] cluster ID
      # @param options [Hash] query options
      # @return [Array<Models::Queue>] list of queues
      def list(cluster_id, options = {})
        validate_cluster_id(cluster_id)
        
        params = { 'ClusterId' => cluster_id }
        response = get('ListQueues', params)
        
        queues_data = response['Queues'] || []
        queues_data.map { |queue_data| Models::Queue.new(queue_data.merge('cluster_id' => cluster_id)) }
      end
      
      # Get queue details
      #
      # @param cluster_id [String] cluster ID
      # @param queue_name [String] queue name
      # @return [Models::Queue] queue object
      def describe(cluster_id, queue_name)
        validate_cluster_id(cluster_id)
        validate_queue_name(queue_name)
        
        params = {
          'ClusterId' => cluster_id,
          'QueueName' => queue_name
        }
        
        response = get('GetQueue', params)
        queue_data = response['QueueInfo'] || response
        
        Models::Queue.new(queue_data.merge('cluster_id' => cluster_id))
      end
      
      # Create a new queue
      #
      # @param cluster_id [String] cluster ID
      # @param queue_config [Hash] queue configuration
      # @return [Models::Queue] created queue object
      def create(cluster_id, queue_config)
        validate_cluster_id(cluster_id)
        validate_create_params(queue_config)
        
        params = build_create_params(cluster_id, queue_config)
        response = post('CreateQueue', params)
        
        # Return the created queue
        describe(cluster_id, queue_config['QueueName'])
      end
      
      # Update queue configuration
      #
      # @param cluster_id [String] cluster ID
      # @param queue_name [String] queue name
      # @param queue_config [Hash] queue configuration updates
      # @return [Models::Queue] updated queue object
      def update(cluster_id, queue_name, queue_config)
        validate_cluster_id(cluster_id)
        validate_queue_name(queue_name)
        validate_update_params(queue_config)
        
        params = build_update_params(cluster_id, queue_name, queue_config)
        response = post('ModifyQueue', params)
        
        # Return the updated queue
        describe(cluster_id, queue_name)
      end
      
      # Delete a queue
      #
      # @param cluster_id [String] cluster ID
      # @param queue_name [String] queue name
      # @return [Boolean] true if successful
      def delete(cluster_id, queue_name)
        validate_cluster_id(cluster_id)
        validate_queue_name(queue_name)
        
        params = {
          'ClusterId' => cluster_id,
          'QueueName' => queue_name
        }
        
        response = post('DeleteQueue', params)
        response['RequestId'] ? true : false
      end
      
      # Start a queue (enable job submission)
      #
      # @param cluster_id [String] cluster ID
      # @param queue_name [String] queue name
      # @return [Boolean] true if successful
      def start(cluster_id, queue_name)
        validate_cluster_id(cluster_id)
        validate_queue_name(queue_name)
        
        params = {
          'ClusterId' => cluster_id,
          'QueueName' => queue_name
        }
        
        response = post('StartQueue', params)
        response['RequestId'] ? true : false
      end
      
      # Stop a queue (disable job submission)
      #
      # @param cluster_id [String] cluster ID
      # @param queue_name [String] queue name
      # @return [Boolean] true if successful
      def stop(cluster_id, queue_name)
        validate_cluster_id(cluster_id)
        validate_queue_name(queue_name)
        
        params = {
          'ClusterId' => cluster_id,
          'QueueName' => queue_name
        }
        
        response = post('StopQueue', params)
        response['RequestId'] ? true : false
      end
      
      # Drain a queue (stop accepting new jobs, let running jobs finish)
      #
      # @param cluster_id [String] cluster ID
      # @param queue_name [String] queue name
      # @return [Boolean] true if successful
      def drain(cluster_id, queue_name)
        validate_cluster_id(cluster_id)
        validate_queue_name(queue_name)
        
        params = {
          'ClusterId' => cluster_id,
          'QueueName' => queue_name,
          'State' => 'Draining'
        }
        
        response = post('ModifyQueueState', params)
        response['RequestId'] ? true : false
      end
      
      # Get queue statistics
      #
      # @param cluster_id [String] cluster ID
      # @param queue_name [String] queue name
      # @param options [Hash] query options
      # @return [Hash] queue statistics
      def statistics(cluster_id, queue_name, options = {})
        validate_cluster_id(cluster_id)
        validate_queue_name(queue_name)
        
        params = {
          'ClusterId' => cluster_id,
          'QueueName' => queue_name,
          'StartTime' => options[:start_time] || (Time.now - 24 * 3600).iso8601,
          'EndTime' => options[:end_time] || Time.now.iso8601
        }
        
        response = get('GetQueueStatistics', params)
        response['Statistics'] || {}
      end
      
      # Get queue jobs
      #
      # @param cluster_id [String] cluster ID
      # @param queue_name [String] queue name
      # @param options [Hash] query options
      # @return [Array<Models::Job>] list of jobs in queue
      def jobs(cluster_id, queue_name, options = {})
        validate_cluster_id(cluster_id)
        validate_queue_name(queue_name)
        
        # Use the job API to list jobs for this queue
        job_api = Job.new(@auth, @config)
        job_api.list(cluster_id, options.merge(queue: queue_name))
      end
      
      # Set queue priority
      #
      # @param cluster_id [String] cluster ID
      # @param queue_name [String] queue name
      # @param priority [Integer] queue priority
      # @return [Boolean] true if successful
      def set_priority(cluster_id, queue_name, priority)
        validate_cluster_id(cluster_id)
        validate_queue_name(queue_name)
        validate_numeric_params({ priority: priority }, { priority: { min: 1, max: 1000 } })
        
        params = {
          'ClusterId' => cluster_id,
          'QueueName' => queue_name,
          'Priority' => priority
        }
        
        response = post('SetQueuePriority', params)
        response['RequestId'] ? true : false
      end
      
      # Set queue limits
      #
      # @param cluster_id [String] cluster ID
      # @param queue_name [String] queue name
      # @param limits [Hash] queue limits configuration
      # @return [Boolean] true if successful
      def set_limits(cluster_id, queue_name, limits)
        validate_cluster_id(cluster_id)
        validate_queue_name(queue_name)
        validate_limits_params(limits)
        
        params = build_limits_params(cluster_id, queue_name, limits)
        response = post('SetQueueLimits', params)
        response['RequestId'] ? true : false
      end
      
      # Add nodes to queue
      #
      # @param cluster_id [String] cluster ID
      # @param queue_name [String] queue name
      # @param node_list [Array<String>] list of node names
      # @return [Boolean] true if successful
      def add_nodes(cluster_id, queue_name, node_list)
        validate_cluster_id(cluster_id)
        validate_queue_name(queue_name)
        validate_array_params({ node_list: node_list }, { node_list: { min_length: 1 } })
        
        params = {
          'ClusterId' => cluster_id,
          'QueueName' => queue_name
        }
        
        node_list.each_with_index do |node, index|
          params["Node.#{index + 1}"] = node
        end
        
        response = post('AddQueueNodes', params)
        response['RequestId'] ? true : false
      end
      
      # Remove nodes from queue
      #
      # @param cluster_id [String] cluster ID
      # @param queue_name [String] queue name
      # @param node_list [Array<String>] list of node names
      # @return [Boolean] true if successful
      def remove_nodes(cluster_id, queue_name, node_list)
        validate_cluster_id(cluster_id)
        validate_queue_name(queue_name)
        validate_array_params({ node_list: node_list }, { node_list: { min_length: 1 } })
        
        params = {
          'ClusterId' => cluster_id,
          'QueueName' => queue_name
        }
        
        node_list.each_with_index do |node, index|
          params["Node.#{index + 1}"] = node
        end
        
        response = post('RemoveQueueNodes', params)
        response['RequestId'] ? true : false
      end
      
      # Set queue access control
      #
      # @param cluster_id [String] cluster ID
      # @param queue_name [String] queue name
      # @param access_config [Hash] access control configuration
      # @return [Boolean] true if successful
      def set_access_control(cluster_id, queue_name, access_config)
        validate_cluster_id(cluster_id)
        validate_queue_name(queue_name)
        validate_access_params(access_config)
        
        params = build_access_params(cluster_id, queue_name, access_config)
        response = post('SetQueueAccess', params)
        response['RequestId'] ? true : false
      end
      
      private
      
      # Validate queue creation parameters
      def validate_create_params(config)
        required_keys = %w[QueueName]
        validate_required_params(config, required_keys)
        
        validate_string_params(config, {
          'QueueName' => { min_length: 1, max_length: 32, pattern: /^[a-zA-Z0-9_-]+$/ },
          'Description' => { max_length: 256 }
        })
        
        if config['Type']
          unless Models::Queue::TYPES.include?(config['Type'])
            raise ValidationError, "Invalid queue type: #{config['Type']}"
          end
        end
      end
      
      # Validate queue update parameters
      def validate_update_params(config)
        if config['Description']
          validate_string_params(config, {
            'Description' => { max_length: 256 }
          })
        end
        
        if config['Type']
          unless Models::Queue::TYPES.include?(config['Type'])
            raise ValidationError, "Invalid queue type: #{config['Type']}"
          end
        end
        
        validate_numeric_attributes(config)
      end
      
      # Validate limits parameters
      def validate_limits_params(limits)
        validate_numeric_params(limits, {
          'MaxNodes' => { min: 1 },
          'MaxCores' => { min: 1 },
          'MaxMemoryMB' => { min: 1 },
          'MaxWalltime' => { min: 1 },
          'MaxJobsPerUser' => { min: 1 },
          'MaxRunningJobs' => { min: 1 },
          'MaxQueuedJobs' => { min: 1 }
        })
      end
      
      # Validate access control parameters
      def validate_access_params(access_config)
        if access_config['AllowedUsers']
          validate_array_params({ allowed_users: access_config['AllowedUsers'] }, {
            allowed_users: { element_type: String }
          })
        end
        
        if access_config['AllowedGroups']
          validate_array_params({ allowed_groups: access_config['AllowedGroups'] }, {
            allowed_groups: { element_type: String }
          })
        end
        
        if access_config['DeniedUsers']
          validate_array_params({ denied_users: access_config['DeniedUsers'] }, {
            denied_users: { element_type: String }
          })
        end
        
        if access_config['DeniedGroups']
          validate_array_params({ denied_groups: access_config['DeniedGroups'] }, {
            denied_groups: { element_type: String }
          })
        end
      end
      
      # Validate numeric attributes
      def validate_numeric_attributes(config)
        numeric_attrs = %w[Priority MaxNodes MaxCores MaxMemoryMB MaxWalltime DefaultWalltime]
        
        numeric_attrs.each do |attr|
          value = config[attr]
          next unless value
          
          if value <= 0
            raise ValidationError, "#{attr} must be positive"
          end
        end
      end
      
      # Build queue creation parameters
      def build_create_params(cluster_id, config)
        params = {
          'ClusterId' => cluster_id,
          'QueueName' => config['QueueName']
        }
        
        params['Description'] = config['Description'] if config['Description']
        params['Type'] = config['Type'] if config['Type']
        params['Priority'] = config['Priority'] if config['Priority']
        params['MaxNodes'] = config['MaxNodes'] if config['MaxNodes']
        params['MaxCores'] = config['MaxCores'] if config['MaxCores']
        params['MaxMemoryMB'] = config['MaxMemoryMB'] if config['MaxMemoryMB']
        params['MaxWalltime'] = config['MaxWalltime'] if config['MaxWalltime']
        params['DefaultWalltime'] = config['DefaultWalltime'] if config['DefaultWalltime']
        
        params
      end
      
      # Build queue update parameters
      def build_update_params(cluster_id, queue_name, config)
        params = {
          'ClusterId' => cluster_id,
          'QueueName' => queue_name
        }
        
        params['Description'] = config['Description'] if config['Description']
        params['Type'] = config['Type'] if config['Type']
        params['Priority'] = config['Priority'] if config['Priority']
        params['MaxNodes'] = config['MaxNodes'] if config['MaxNodes']
        params['MaxCores'] = config['MaxCores'] if config['MaxCores']
        params['MaxMemoryMB'] = config['MaxMemoryMB'] if config['MaxMemoryMB']
        params['MaxWalltime'] = config['MaxWalltime'] if config['MaxWalltime']
        params['DefaultWalltime'] = config['DefaultWalltime'] if config['DefaultWalltime']
        
        params
      end
      
      # Build limits parameters
      def build_limits_params(cluster_id, queue_name, limits)
        params = {
          'ClusterId' => cluster_id,
          'QueueName' => queue_name
        }
        
        params['MaxNodes'] = limits['MaxNodes'] if limits['MaxNodes']
        params['MaxCores'] = limits['MaxCores'] if limits['MaxCores']
        params['MaxMemoryMB'] = limits['MaxMemoryMB'] if limits['MaxMemoryMB']
        params['MaxWalltime'] = limits['MaxWalltime'] if limits['MaxWalltime']
        params['MaxJobsPerUser'] = limits['MaxJobsPerUser'] if limits['MaxJobsPerUser']
        params['MaxRunningJobs'] = limits['MaxRunningJobs'] if limits['MaxRunningJobs']
        params['MaxQueuedJobs'] = limits['MaxQueuedJobs'] if limits['MaxQueuedJobs']
        
        params
      end
      
      # Build access control parameters
      def build_access_params(cluster_id, queue_name, access_config)
        params = {
          'ClusterId' => cluster_id,
          'QueueName' => queue_name
        }
        
        if access_config['AllowedUsers']
          access_config['AllowedUsers'].each_with_index do |user, index|
            params["AllowedUser.#{index + 1}"] = user
          end
        end
        
        if access_config['AllowedGroups']
          access_config['AllowedGroups'].each_with_index do |group, index|
            params["AllowedGroup.#{index + 1}"] = group
          end
        end
        
        if access_config['DeniedUsers']
          access_config['DeniedUsers'].each_with_index do |user, index|
            params["DeniedUser.#{index + 1}"] = user
          end
        end
        
        if access_config['DeniedGroups']
          access_config['DeniedGroups'].each_with_index do |group, index|
            params["DeniedGroup.#{index + 1}"] = group
          end
        end
        
        params
      end
    end
  end
end
