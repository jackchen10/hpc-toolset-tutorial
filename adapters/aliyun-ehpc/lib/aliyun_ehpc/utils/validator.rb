# frozen_string_literal: true

module AliyunEhpc
  module Utils
    # Parameter validation utilities
    module Validator
      # Validate required parameters
      #
      # @param params [Hash] parameters to validate
      # @param required_keys [Array] list of required parameter keys
      # @raise [ValidationError] if required parameters are missing
      def validate_required_params(params, required_keys)
        missing_keys = required_keys - params.keys
        
        unless missing_keys.empty?
          raise ValidationError, "Missing required parameters: #{missing_keys.join(', ')}"
        end
      end
      
      # Validate parameter types
      #
      # @param params [Hash] parameters to validate
      # @param type_specs [Hash] type specifications (key => expected_type)
      # @raise [ValidationError] if parameter types are invalid
      def validate_param_types(params, type_specs)
        type_specs.each do |key, expected_type|
          next unless params.key?(key)
          
          value = params[key]
          next if value.nil? # Allow nil values
          
          unless value.is_a?(expected_type)
            raise ValidationError, 
                  "Parameter '#{key}' must be of type #{expected_type}, got #{value.class}"
          end
        end
      end
      
      # Validate string parameters
      #
      # @param params [Hash] parameters to validate
      # @param string_specs [Hash] string specifications (key => options)
      # @raise [ValidationError] if string parameters are invalid
      def validate_string_params(params, string_specs)
        string_specs.each do |key, options|
          next unless params.key?(key)
          
          value = params[key]
          next if value.nil?
          
          unless value.is_a?(String)
            raise ValidationError, "Parameter '#{key}' must be a string, got #{value.class}"
          end
          
          validate_string_length(key, value, options)
          validate_string_pattern(key, value, options)
          validate_string_values(key, value, options)
        end
      end
      
      # Validate numeric parameters
      #
      # @param params [Hash] parameters to validate
      # @param numeric_specs [Hash] numeric specifications (key => options)
      # @raise [ValidationError] if numeric parameters are invalid
      def validate_numeric_params(params, numeric_specs)
        numeric_specs.each do |key, options|
          next unless params.key?(key)
          
          value = params[key]
          next if value.nil?
          
          unless value.is_a?(Numeric)
            raise ValidationError, "Parameter '#{key}' must be numeric, got #{value.class}"
          end
          
          validate_numeric_range(key, value, options)
        end
      end
      
      # Validate array parameters
      #
      # @param params [Hash] parameters to validate
      # @param array_specs [Hash] array specifications (key => options)
      # @raise [ValidationError] if array parameters are invalid
      def validate_array_params(params, array_specs)
        array_specs.each do |key, options|
          next unless params.key?(key)
          
          value = params[key]
          next if value.nil?
          
          unless value.is_a?(Array)
            raise ValidationError, "Parameter '#{key}' must be an array, got #{value.class}"
          end
          
          validate_array_length(key, value, options)
          validate_array_elements(key, value, options)
        end
      end
      
      # Validate cluster ID format
      #
      # @param cluster_id [String] cluster ID to validate
      # @raise [ValidationError] if cluster ID is invalid
      def validate_cluster_id(cluster_id)
        return if cluster_id.nil?
        
        unless cluster_id.is_a?(String) && !cluster_id.empty?
          raise ValidationError, 'cluster_id must be a non-empty string'
        end
        
        unless cluster_id.match?(/^ehpc-[a-zA-Z0-9-]+$/)
          raise ValidationError, 'cluster_id must match pattern: ehpc-[a-zA-Z0-9-]+'
        end
      end
      
      # Validate job ID format
      #
      # @param job_id [String] job ID to validate
      # @raise [ValidationError] if job ID is invalid
      def validate_job_id(job_id)
        return if job_id.nil?
        
        unless job_id.is_a?(String) && !job_id.empty?
          raise ValidationError, 'job_id must be a non-empty string'
        end
        
        unless job_id.match?(/^[a-zA-Z0-9-]+$/)
          raise ValidationError, 'job_id must contain only alphanumeric characters and hyphens'
        end
      end
      
      # Validate user ID format
      #
      # @param user_id [String] user ID to validate
      # @raise [ValidationError] if user ID is invalid
      def validate_user_id(user_id)
        return if user_id.nil?
        
        unless user_id.is_a?(String) && !user_id.empty?
          raise ValidationError, 'user_id must be a non-empty string'
        end
        
        unless user_id.match?(/^[a-zA-Z0-9._-]+$/)
          raise ValidationError, 'user_id must contain only alphanumeric characters, dots, underscores, and hyphens'
        end
      end
      
      # Validate queue name format
      #
      # @param queue_name [String] queue name to validate
      # @raise [ValidationError] if queue name is invalid
      def validate_queue_name(queue_name)
        return if queue_name.nil?
        
        unless queue_name.is_a?(String) && !queue_name.empty?
          raise ValidationError, 'queue_name must be a non-empty string'
        end
        
        unless queue_name.match?(/^[a-zA-Z0-9_-]+$/)
          raise ValidationError, 'queue_name must contain only alphanumeric characters, underscores, and hyphens'
        end
      end
      
      # Validate time format (ISO8601 or Unix timestamp)
      #
      # @param time_value [String, Integer] time value to validate
      # @raise [ValidationError] if time format is invalid
      def validate_time_format(time_value)
        return if time_value.nil?
        
        case time_value
        when String
          begin
            Time.parse(time_value)
          rescue ArgumentError
            raise ValidationError, 'time must be in ISO8601 format'
          end
        when Integer
          if time_value < 0
            raise ValidationError, 'Unix timestamp must be non-negative'
          end
        else
          raise ValidationError, 'time must be a string (ISO8601) or integer (Unix timestamp)'
        end
      end
      
      private
      
      # Validate string length
      def validate_string_length(key, value, options)
        if options[:min_length] && value.length < options[:min_length]
          raise ValidationError, "Parameter '#{key}' must be at least #{options[:min_length]} characters long"
        end
        
        if options[:max_length] && value.length > options[:max_length]
          raise ValidationError, "Parameter '#{key}' must be at most #{options[:max_length]} characters long"
        end
      end
      
      # Validate string pattern
      def validate_string_pattern(key, value, options)
        if options[:pattern] && !value.match?(options[:pattern])
          raise ValidationError, "Parameter '#{key}' does not match required pattern"
        end
      end
      
      # Validate string values
      def validate_string_values(key, value, options)
        if options[:values] && !options[:values].include?(value)
          raise ValidationError, "Parameter '#{key}' must be one of: #{options[:values].join(', ')}"
        end
      end
      
      # Validate numeric range
      def validate_numeric_range(key, value, options)
        min_val = options[:min]
        max_val = options[:max]

        # Ensure min and max are numeric values, not arrays
        min_val = min_val.is_a?(Array) ? min_val.first : min_val
        max_val = max_val.is_a?(Array) ? max_val.first : max_val

        if min_val && value < min_val
          raise ValidationError, "Parameter '#{key}' must be at least #{min_val}"
        end

        if max_val && value > max_val
          raise ValidationError, "Parameter '#{key}' must be at most #{max_val}"
        end
      end
      
      # Validate array length
      def validate_array_length(key, value, options)
        if options[:min_length] && value.length < options[:min_length]
          raise ValidationError, "Parameter '#{key}' must have at least #{options[:min_length]} elements"
        end
        
        if options[:max_length] && value.length > options[:max_length]
          raise ValidationError, "Parameter '#{key}' must have at most #{options[:max_length]} elements"
        end
      end
      
      # Validate array elements
      def validate_array_elements(key, value, options)
        if options[:element_type]
          value.each_with_index do |element, index|
            unless element.is_a?(options[:element_type])
              raise ValidationError, 
                    "Parameter '#{key}[#{index}]' must be of type #{options[:element_type]}, got #{element.class}"
            end
          end
        end
      end
    end
  end
end
