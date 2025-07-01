# frozen_string_literal: true

module AliyunEhpc
  module API
    # Job management API client
    class Job < Base
      # Submit a job
      #
      # @param cluster_id [String] cluster ID
      # @param job_config [Hash] job configuration
      # @return [Models::Job] submitted job object
      def submit(cluster_id, job_config)
        validate_cluster_id(cluster_id)
        validate_submit_params(job_config)
        
        params = build_submit_params(cluster_id, job_config)
        response = post('SubmitJob', params)
        
        job_id = response['JobId']
        describe(cluster_id, job_id)
      end
      
      # Get job details
      #
      # @param cluster_id [String] cluster ID
      # @param job_id [String] job ID
      # @return [Models::Job] job object
      def describe(cluster_id, job_id)
        validate_cluster_id(cluster_id)
        validate_job_id(job_id)
        
        params = {
          'ClusterId' => cluster_id,
          'JobId' => job_id
        }
        
        response = get('GetJobLog', params)
        job_data = response['JobInfo'] || response
        
        Models::Job.new(job_data.merge('cluster_id' => cluster_id))
      end
      
      # List jobs
      #
      # @param cluster_id [String] cluster ID
      # @param options [Hash] query options
      # @return [Array<Models::Job>] list of jobs
      def list(cluster_id, options = {})
        validate_cluster_id(cluster_id)
        validate_list_params(options)
        
        params = build_list_params(cluster_id, options)
        
        if options[:paginate]
          paginate('ListJobs', params, options) do |page_results|
            yield page_results.map { |job_data| Models::Job.new(job_data.merge('cluster_id' => cluster_id)) }
          end
        else
          response = get('ListJobs', params)
          jobs_data = response['Jobs'] || []
          jobs_data.map { |job_data| Models::Job.new(job_data.merge('cluster_id' => cluster_id)) }
        end
      end
      
      # Cancel a job
      #
      # @param cluster_id [String] cluster ID
      # @param job_id [String] job ID
      # @return [Boolean] true if successful
      def cancel(cluster_id, job_id)
        validate_cluster_id(cluster_id)
        validate_job_id(job_id)
        
        params = {
          'ClusterId' => cluster_id,
          'JobId' => job_id
        }
        
        response = post('DeleteJobs', params)
        response['RequestId'] ? true : false
      end
      
      # Requeue a job
      #
      # @param cluster_id [String] cluster ID
      # @param job_id [String] job ID
      # @return [Boolean] true if successful
      def requeue(cluster_id, job_id)
        validate_cluster_id(cluster_id)
        validate_job_id(job_id)
        
        params = {
          'ClusterId' => cluster_id,
          'JobId' => job_id
        }
        
        response = post('RerunJobs', params)
        response['RequestId'] ? true : false
      end
      
      # Get job output
      #
      # @param cluster_id [String] cluster ID
      # @param job_id [String] job ID
      # @param options [Hash] output options
      # @return [Hash] job output information
      def output(cluster_id, job_id, options = {})
        validate_cluster_id(cluster_id)
        validate_job_id(job_id)
        
        params = {
          'ClusterId' => cluster_id,
          'JobId' => job_id
        }
        
        params['Size'] = options[:size] if options[:size]
        params['Offset'] = options[:offset] if options[:offset]
        
        response = get('GetJobLog', params)
        {
          stdout: response['StdOut'] || '',
          stderr: response['StdErr'] || '',
          log_info: response['LogInfo'] || {}
        }
      end
      
      # Get job metrics
      #
      # @param cluster_id [String] cluster ID
      # @param job_id [String] job ID
      # @param options [Hash] metrics options
      # @return [Hash] job metrics
      def metrics(cluster_id, job_id, options = {})
        validate_cluster_id(cluster_id)
        validate_job_id(job_id)
        
        params = {
          'ClusterId' => cluster_id,
          'JobId' => job_id,
          'MetricName' => options[:metric_name] || 'CPUUtilization',
          'Period' => options[:period] || 300
        }
        
        if options[:start_time]
          params['StartTime'] = options[:start_time]
        end
        
        if options[:end_time]
          params['EndTime'] = options[:end_time]
        end
        
        response = get('GetJobMetrics', params)
        response['Datapoints'] || []
      end
      
      # Submit job array
      #
      # @param cluster_id [String] cluster ID
      # @param job_config [Hash] job configuration
      # @param array_spec [String] array specification (e.g., "1-10", "1,3,5")
      # @return [Array<Models::Job>] submitted job array
      def submit_array(cluster_id, job_config, array_spec)
        validate_cluster_id(cluster_id)
        validate_submit_params(job_config)
        validate_array_spec(array_spec)
        
        # Add array specification to job config
        job_config_with_array = job_config.merge('ArrayRequest' => array_spec)
        
        params = build_submit_params(cluster_id, job_config_with_array)
        response = post('SubmitJob', params)
        
        # Parse array job IDs from response
        job_ids = parse_array_job_ids(response['JobId'], array_spec)
        
        # Return array of job objects
        job_ids.map { |job_id| describe(cluster_id, job_id) }
      end
      
      # Get job dependencies
      #
      # @param cluster_id [String] cluster ID
      # @param job_id [String] job ID
      # @return [Array<String>] list of dependency job IDs
      def dependencies(cluster_id, job_id)
        validate_cluster_id(cluster_id)
        validate_job_id(job_id)
        
        job = describe(cluster_id, job_id)
        job.dependency_list || []
      end
      
      # Set job priority
      #
      # @param cluster_id [String] cluster ID
      # @param job_id [String] job ID
      # @param priority [String] job priority (Low, Normal, High, Urgent)
      # @return [Boolean] true if successful
      def set_priority(cluster_id, job_id, priority)
        validate_cluster_id(cluster_id)
        validate_job_id(job_id)
        
        unless Models::Job::PRIORITIES.include?(priority)
          raise ValidationError, "Invalid priority: #{priority}. Must be one of: #{Models::Job::PRIORITIES.join(', ')}"
        end
        
        params = {
          'ClusterId' => cluster_id,
          'JobId' => job_id,
          'Priority' => priority
        }
        
        response = post('ModifyJobPriority', params)
        response['RequestId'] ? true : false
      end
      
      # Hold a job (prevent it from running)
      #
      # @param cluster_id [String] cluster ID
      # @param job_id [String] job ID
      # @return [Boolean] true if successful
      def hold(cluster_id, job_id)
        validate_cluster_id(cluster_id)
        validate_job_id(job_id)
        
        params = {
          'ClusterId' => cluster_id,
          'JobId' => job_id
        }
        
        response = post('HoldJobs', params)
        response['RequestId'] ? true : false
      end
      
      # Release a held job
      #
      # @param cluster_id [String] cluster ID
      # @param job_id [String] job ID
      # @return [Boolean] true if successful
      def release(cluster_id, job_id)
        validate_cluster_id(cluster_id)
        validate_job_id(job_id)
        
        params = {
          'ClusterId' => cluster_id,
          'JobId' => job_id
        }
        
        response = post('ReleaseJobs', params)
        response['RequestId'] ? true : false
      end
      
      private
      
      # Validate job submission parameters
      def validate_submit_params(config)
        required_keys = %w[Name CommandLine]
        validate_required_params(config, required_keys)
        
        validate_string_params(config, {
          'Name' => { min_length: 1, max_length: 64 },
          'CommandLine' => { min_length: 1 },
          'WorkingDir' => { max_length: 256 },
          'StdoutRedirectPath' => { max_length: 256 },
          'StderrRedirectPath' => { max_length: 256 }
        })
        
        if config['Priority']
          unless Models::Job::PRIORITIES.include?(config['Priority'])
            raise ValidationError, "Invalid priority: #{config['Priority']}"
          end
        end
      end
      
      # Validate list parameters
      def validate_list_params(options)
        if options[:page_size]
          validate_numeric_params({ page_size: options[:page_size] }, { page_size: { min: 1, max: 100 } })
        end
        
        if options[:page_number]
          validate_numeric_params({ page_number: options[:page_number] }, { page_number: { min: 1 } })
        end
        
        if options[:state]
          unless Models::Job::STATES.include?(options[:state])
            raise ValidationError, "Invalid job state: #{options[:state]}"
          end
        end
      end
      
      # Build job submission parameters
      def build_submit_params(cluster_id, config)
        params = {
          'ClusterId' => cluster_id,
          'Name' => config['Name'],
          'CommandLine' => config['CommandLine']
        }
        
        # Add optional parameters
        params['WorkingDir'] = config['WorkingDir'] if config['WorkingDir']
        params['Priority'] = config['Priority'] if config['Priority']
        params['StdoutRedirectPath'] = config['StdoutRedirectPath'] if config['StdoutRedirectPath']
        params['StderrRedirectPath'] = config['StderrRedirectPath'] if config['StderrRedirectPath']
        params['ReRunable'] = config['ReRunable'] if config['ReRunable']
        params['ArrayRequest'] = config['ArrayRequest'] if config['ArrayRequest']
        params['PackageId'] = config['PackageId'] if config['PackageId']
        params['JobQueue'] = config['JobQueue'] if config['JobQueue']
        params['Variables'] = config['Variables'] if config['Variables']
        params['InputFileUrl'] = config['InputFileUrl'] if config['InputFileUrl']
        params['PostCmdLine'] = config['PostCmdLine'] if config['PostCmdLine']
        params['ClockTime'] = config['ClockTime'] if config['ClockTime']
        params['MemSize'] = config['MemSize'] if config['MemSize']
        params['Thread'] = config['Thread'] if config['Thread']
        params['Gpu'] = config['Gpu'] if config['Gpu']
        params['Node'] = config['Node'] if config['Node']
        params['Task'] = config['Task'] if config['Task']
        
        params.compact
      end
      
      # Build job list parameters
      def build_list_params(cluster_id, options)
        params = { 'ClusterId' => cluster_id }
        
        params['PageSize'] = options[:page_size] if options[:page_size]
        params['PageNumber'] = options[:page_number] if options[:page_number]
        params['State'] = options[:state] if options[:state]
        params['Owner'] = options[:owner] if options[:owner]
        params['JobQueue'] = options[:queue] if options[:queue]
        params['JobName'] = options[:name] if options[:name]
        
        params
      end
      
      # Validate array specification
      def validate_array_spec(array_spec)
        unless array_spec.match?(/^(\d+(-\d+)?(:\d+)?)(,\d+(-\d+)?(:\d+)?)*$/)
          raise ValidationError, 'Invalid array specification format'
        end
      end
      
      # Parse array job IDs from response
      def parse_array_job_ids(job_id_response, array_spec)
        # This is a simplified implementation
        # In reality, you'd need to parse the array spec and generate job IDs
        base_job_id = job_id_response.split('_').first
        
        # Parse array indices from spec
        indices = parse_array_indices(array_spec)
        
        # Generate job IDs for each array index
        indices.map { |index| "#{base_job_id}_#{index}" }
      end
      
      # Parse array indices from specification
      def parse_array_indices(array_spec)
        indices = []
        
        array_spec.split(',').each do |part|
          if part.include?('-')
            # Range specification (e.g., "1-10")
            range_parts = part.split('-')
            start_idx = range_parts[0].to_i
            end_idx = range_parts[1].to_i
            step = part.include?(':') ? part.split(':')[1].to_i : 1
            
            (start_idx..end_idx).step(step) { |i| indices << i }
          else
            # Single index
            indices << part.to_i
          end
        end
        
        indices.sort.uniq
      end
    end
  end
end
