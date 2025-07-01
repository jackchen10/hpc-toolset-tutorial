# frozen_string_literal: true

require 'logger'

module AliyunEhpc
  module Utils
    # Enhanced logger with structured logging support
    class Logger
      attr_reader :logger, :level
      
      # Log levels
      LEVELS = {
        debug: ::Logger::DEBUG,
        info: ::Logger::INFO,
        warn: ::Logger::WARN,
        error: ::Logger::ERROR,
        fatal: ::Logger::FATAL
      }.freeze
      
      def initialize(level = :info, output = $stdout)
        @level = level
        @logger = ::Logger.new(output)
        @logger.level = LEVELS[level] || ::Logger::INFO
        @logger.formatter = method(:format_message)
      end
      
      # Log debug message
      #
      # @param message [String] log message
      # @param context [Hash] additional context
      def debug(message, context = {})
        log(:debug, message, context)
      end
      
      # Log info message
      #
      # @param message [String] log message
      # @param context [Hash] additional context
      def info(message, context = {})
        log(:info, message, context)
      end
      
      # Log warning message
      #
      # @param message [String] log message
      # @param context [Hash] additional context
      def warn(message, context = {})
        log(:warn, message, context)
      end
      
      # Log error message
      #
      # @param message [String] log message
      # @param context [Hash] additional context
      def error(message, context = {})
        log(:error, message, context)
      end
      
      # Log fatal message
      #
      # @param message [String] log message
      # @param context [Hash] additional context
      def fatal(message, context = {})
        log(:fatal, message, context)
      end
      
      # Log API request
      #
      # @param method [String] HTTP method
      # @param url [String] request URL
      # @param params [Hash] request parameters
      # @param duration [Float] request duration in seconds
      def log_api_request(method, url, params = {}, duration = nil)
        context = {
          type: 'api_request',
          method: method,
          url: url,
          params_count: params.size,
          duration: duration
        }
        
        message = "API Request: #{method} #{url}"
        message += " (#{duration}s)" if duration
        
        info(message, context)
      end
      
      # Log API response
      #
      # @param status [Integer] HTTP status code
      # @param response_size [Integer] response size in bytes
      # @param duration [Float] request duration in seconds
      def log_api_response(status, response_size = nil, duration = nil)
        context = {
          type: 'api_response',
          status: status,
          response_size: response_size,
          duration: duration
        }
        
        message = "API Response: #{status}"
        message += " (#{response_size} bytes)" if response_size
        message += " (#{duration}s)" if duration
        
        if status >= 200 && status < 300
          info(message, context)
        elsif status >= 400 && status < 500
          warn(message, context)
        else
          error(message, context)
        end
      end
      
      # Log exception with full context
      #
      # @param exception [Exception] exception object
      # @param context [Hash] additional context
      def log_exception(exception, context = {})
        error_context = {
          type: 'exception',
          exception_class: exception.class.name,
          exception_message: exception.message,
          backtrace: exception.backtrace&.first(10)
        }.merge(context)
        
        error("Exception: #{exception.class.name}: #{exception.message}", error_context)
      end
      
      # Log job operation
      #
      # @param operation [String] operation type (submit, cancel, etc.)
      # @param job_id [String] job ID
      # @param cluster_id [String] cluster ID
      # @param context [Hash] additional context
      def log_job_operation(operation, job_id, cluster_id, context = {})
        job_context = {
          type: 'job_operation',
          operation: operation,
          job_id: job_id,
          cluster_id: cluster_id
        }.merge(context)
        
        info("Job #{operation}: #{job_id} on cluster #{cluster_id}", job_context)
      end
      
      # Check if level is enabled
      #
      # @param level [Symbol] log level
      # @return [Boolean] true if level is enabled
      def level_enabled?(level)
        @logger.level <= LEVELS[level]
      end
      
      private
      
      # Generic log method
      #
      # @param level [Symbol] log level
      # @param message [String] log message
      # @param context [Hash] additional context
      def log(level, message, context = {})
        return unless level_enabled?(level)
        
        log_data = {
          timestamp: Time.now.utc.iso8601,
          level: level.to_s.upcase,
          message: message,
          gem: 'aliyun_ehpc',
          version: AliyunEhpc::VERSION
        }
        
        log_data.merge!(context) unless context.empty?
        
        @logger.send(level, log_data)
      end
      
      # Format log message
      #
      # @param severity [String] log severity
      # @param datetime [Time] log timestamp
      # @param progname [String] program name
      # @param msg [Object] log message/data
      # @return [String] formatted message
      def format_message(severity, datetime, progname, msg)
        if msg.is_a?(Hash)
          # Structured logging format
          timestamp = datetime.strftime('%Y-%m-%d %H:%M:%S.%3N')
          json_msg = JSON.generate(msg)
          "[#{timestamp}] #{severity}: #{json_msg}\n"
        else
          # Simple string format
          timestamp = datetime.strftime('%Y-%m-%d %H:%M:%S.%3N')
          "[#{timestamp}] #{severity}: #{msg}\n"
        end
      rescue JSON::GeneratorError
        # Fallback to simple format if JSON generation fails
        timestamp = datetime.strftime('%Y-%m-%d %H:%M:%S.%3N')
        "[#{timestamp}] #{severity}: #{msg.inspect}\n"
      end
    end
  end
end
