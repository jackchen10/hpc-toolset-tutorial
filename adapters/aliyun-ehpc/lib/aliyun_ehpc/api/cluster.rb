# frozen_string_literal: true

module AliyunEhpc
  module API
    # Cluster management API client
    class Cluster < Base
      # List all clusters
      #
      # @param params [Hash] optional parameters
      # @return [Array<Models::Cluster>] list of clusters
      def list(params = {})
        validate_list_params(params)
        
        response = get('ListClusters', params)
        clusters_data = response['Clusters'] || []
        
        clusters_data.map { |cluster_data| Models::Cluster.new(cluster_data) }
      end
      
      # Get cluster details
      #
      # @param cluster_id [String] cluster ID
      # @return [Models::Cluster] cluster object
      def describe(cluster_id)
        validate_cluster_id(cluster_id)
        
        params = { 'ClusterId' => cluster_id }
        response = get('DescribeCluster', params)
        
        cluster_data = response['ClusterInfo'] || response
        Models::Cluster.new(cluster_data)
      end
      
      # Create a new cluster
      #
      # @param cluster_config [Hash] cluster configuration
      # @return [Models::Cluster] created cluster object
      def create(cluster_config)
        validate_create_params(cluster_config)
        
        params = build_create_params(cluster_config)
        response = post('CreateCluster', params)
        
        cluster_id = response['ClusterId']
        describe(cluster_id)
      end
      
      # Delete a cluster
      #
      # @param cluster_id [String] cluster ID
      # @param options [Hash] deletion options
      # @return [Boolean] true if successful
      def delete(cluster_id, options = {})
        validate_cluster_id(cluster_id)
        
        params = {
          'ClusterId' => cluster_id,
          'ReleaseInstance' => options[:release_instance] || 'true'
        }
        
        response = post('DeleteCluster', params)
        response['RequestId'] ? true : false
      end
      
      # Start a cluster
      #
      # @param cluster_id [String] cluster ID
      # @return [Boolean] true if successful
      def start(cluster_id)
        validate_cluster_id(cluster_id)
        
        params = { 'ClusterId' => cluster_id }
        response = post('StartCluster', params)
        response['RequestId'] ? true : false
      end
      
      # Stop a cluster
      #
      # @param cluster_id [String] cluster ID
      # @return [Boolean] true if successful
      def stop(cluster_id)
        validate_cluster_id(cluster_id)
        
        params = { 'ClusterId' => cluster_id }
        response = post('StopCluster', params)
        response['RequestId'] ? true : false
      end
      
      # Scale cluster nodes
      #
      # @param cluster_id [String] cluster ID
      # @param node_count [Integer] target node count
      # @param options [Hash] scaling options
      # @return [Boolean] true if successful
      def scale(cluster_id, node_count, options = {})
        validate_cluster_id(cluster_id)
        validate_numeric_params({ node_count: node_count }, { node_count: { min: 0 } })
        
        params = {
          'ClusterId' => cluster_id,
          'Count' => node_count
        }
        
        # Add optional parameters
        params['InstanceType'] = options[:instance_type] if options[:instance_type]
        params['ImageId'] = options[:image_id] if options[:image_id]
        
        if node_count > 0
          response = post('AddNodes', params)
        else
          # For scaling down, we need to specify which nodes to remove
          response = post('DeleteNodes', params.merge('Instance.1' => options[:instance_id]))
        end
        
        response['RequestId'] ? true : false
      end
      
      # Get cluster nodes
      #
      # @param cluster_id [String] cluster ID
      # @param options [Hash] query options
      # @return [Array<Hash>] list of nodes
      def nodes(cluster_id, options = {})
        validate_cluster_id(cluster_id)
        
        params = { 'ClusterId' => cluster_id }
        params['Role'] = options[:role] if options[:role]
        params['HostName'] = options[:hostname] if options[:hostname]
        
        response = get('ListNodes', params)
        response['Nodes'] || []
      end
      
      # Get cluster queues
      #
      # @param cluster_id [String] cluster ID
      # @return [Array<Models::Queue>] list of queues
      def queues(cluster_id)
        validate_cluster_id(cluster_id)
        
        params = { 'ClusterId' => cluster_id }
        response = get('ListQueues', params)
        
        queues_data = response['Queues'] || []
        queues_data.map { |queue_data| Models::Queue.new(queue_data.merge('cluster_id' => cluster_id)) }
      end
      
      # Get cluster software
      #
      # @param cluster_id [String] cluster ID
      # @return [Array<Hash>] list of installed software
      def software(cluster_id)
        validate_cluster_id(cluster_id)
        
        params = { 'ClusterId' => cluster_id }
        response = get('ListSoftwares', params)
        response['Softwares'] || []
      end
      
      # Install software on cluster
      #
      # @param cluster_id [String] cluster ID
      # @param software_list [Array<String>] list of software to install
      # @return [Boolean] true if successful
      def install_software(cluster_id, software_list)
        validate_cluster_id(cluster_id)
        validate_array_params({ software_list: software_list }, { software_list: { min_length: 1 } })
        
        params = { 'ClusterId' => cluster_id }
        software_list.each_with_index do |software, index|
          params["Application.#{index + 1}.Tag"] = software
        end
        
        response = post('InstallSoftware', params)
        response['RequestId'] ? true : false
      end
      
      # Uninstall software from cluster
      #
      # @param cluster_id [String] cluster ID
      # @param software_list [Array<String>] list of software to uninstall
      # @return [Boolean] true if successful
      def uninstall_software(cluster_id, software_list)
        validate_cluster_id(cluster_id)
        validate_array_params({ software_list: software_list }, { software_list: { min_length: 1 } })
        
        params = { 'ClusterId' => cluster_id }
        software_list.each_with_index do |software, index|
          params["Application.#{index + 1}.Tag"] = software
        end
        
        response = post('UninstallSoftware', params)
        response['RequestId'] ? true : false
      end
      
      # Get cluster metrics
      #
      # @param cluster_id [String] cluster ID
      # @param options [Hash] metrics options
      # @return [Hash] cluster metrics
      def metrics(cluster_id, options = {})
        validate_cluster_id(cluster_id)
        
        params = {
          'ClusterId' => cluster_id,
          'MetricName' => options[:metric_name] || 'CPUUtilization',
          'Period' => options[:period] || 300,
          'StartTime' => options[:start_time] || (Time.now - 3600).iso8601,
          'EndTime' => options[:end_time] || Time.now.iso8601
        }
        
        response = get('GetClusterMetrics', params)
        response['Datapoints'] || []
      end
      
      private
      
      # Validate list parameters
      def validate_list_params(params)
        if params[:page_size]
          validate_numeric_params({ page_size: params[:page_size] }, { page_size: { min: 1, max: 100 } })
        end
        
        if params[:page_number]
          validate_numeric_params({ page_number: params[:page_number] }, { page_number: { min: 1 } })
        end
      end
      
      # Validate cluster creation parameters
      def validate_create_params(config)
        required_keys = %w[Name EhpcVersion OsTag InstanceType LoginCount ComputeCount]
        validate_required_params(config, required_keys)
        
        validate_string_params(config, {
          'Name' => { min_length: 2, max_length: 64 },
          'Description' => { max_length: 256 },
          'EhpcVersion' => { values: %w[1.0.0 2.0.0] },
          'OsTag' => { pattern: /^[a-zA-Z0-9._-]+$/ },
          'InstanceType' => { pattern: /^ecs\.[a-z0-9.-]+$/ }
        })
        
        validate_numeric_params(config, {
          'LoginCount' => { min: 1, max: 8 },
          'ComputeCount' => { min: 1, max: 99 }
        })
      end
      
      # Build cluster creation parameters
      def build_create_params(config)
        params = {
          'Name' => config['Name'],
          'Description' => config['Description'] || '',
          'EhpcVersion' => config['EhpcVersion'],
          'OsTag' => config['OsTag'],
          'InstanceType' => config['InstanceType'],
          'LoginCount' => config['LoginCount'],
          'ComputeCount' => config['ComputeCount']
        }
        
        # Add optional parameters
        params['VpcId'] = config['VpcId'] if config['VpcId']
        params['VSwitchId'] = config['VSwitchId'] if config['VSwitchId']
        params['SecurityGroupId'] = config['SecurityGroupId'] if config['SecurityGroupId']
        params['KeyPairName'] = config['KeyPairName'] if config['KeyPairName']
        params['Password'] = config['Password'] if config['Password']
        params['ImageId'] = config['ImageId'] if config['ImageId']
        params['ImageOwnerAlias'] = config['ImageOwnerAlias'] if config['ImageOwnerAlias']
        params['ClientVersion'] = config['ClientVersion'] if config['ClientVersion']
        params['AccountType'] = config['AccountType'] if config['AccountType']
        params['SchedulerType'] = config['SchedulerType'] if config['SchedulerType']
        
        # Add compute instance configuration
        if config['ComputeInstanceType']
          params['ComputeInstanceType'] = config['ComputeInstanceType']
        end
        
        # Add login instance configuration
        if config['LoginInstanceType']
          params['LoginInstanceType'] = config['LoginInstanceType']
        end
        
        # Add manager instance configuration
        if config['ManagerInstanceType']
          params['ManagerInstanceType'] = config['ManagerInstanceType']
        end
        
        # Add storage configuration
        if config['VolumeType']
          params['VolumeType'] = config['VolumeType']
          params['VolumeSize'] = config['VolumeSize'] if config['VolumeSize']
        end
        
        # Add network configuration
        if config['EipBandwidth']
          params['EipBandwidth'] = config['EipBandwidth']
        end
        
        # Add software configuration
        if config['Application']
          config['Application'].each_with_index do |app, index|
            params["Application.#{index + 1}.Tag"] = app['Tag']
            params["Application.#{index + 1}.Name"] = app['Name'] if app['Name']
          end
        end
        
        # Add post install script
        if config['PostInstallScript']
          config['PostInstallScript'].each_with_index do |script, index|
            params["PostInstallScript.#{index + 1}.Args"] = script['Args']
            params["PostInstallScript.#{index + 1}.Url"] = script['Url']
          end
        end
        
        params.compact
      end
    end
  end
end
