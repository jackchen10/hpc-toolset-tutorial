# frozen_string_literal: true

require 'net/http'

module AliyunEhpc
  module Utils
    # Retry mechanism with exponential backoff
    module Retry
      # Default retry configuration
      DEFAULT_RETRY_COUNT = 3
      DEFAULT_RETRY_DELAY = 1
      DEFAULT_MAX_DELAY = 60
      DEFAULT_BACKOFF_FACTOR = 2
      
      # Retryable error classes
      RETRYABLE_ERRORS = [
        NetworkError,
        TimeoutError,
        Errno::ECONNRESET,
        Errno::ECONNREFUSED,
        Errno::ETIMEDOUT,
        Net::ReadTimeout,
        Net::OpenTimeout
      ].freeze
      
      # Execute block with retry logic
      #
      # @param max_retries [Integer] maximum number of retries
      # @param delay [Numeric] initial delay between retries
      # @param max_delay [Numeric] maximum delay between retries
      # @param backoff_factor [Numeric] exponential backoff factor
      # @param retryable_errors [Array] list of retryable error classes
      # @yield block to execute with retry
      # @return [Object] result of the block
      def with_retry(max_retries: DEFAULT_RETRY_COUNT,
                     delay: DEFAULT_RETRY_DELAY,
                     max_delay: DEFAULT_MAX_DELAY,
                     backoff_factor: DEFAULT_BACKOFF_FACTOR,
                     retryable_errors: RETRYABLE_ERRORS,
                     &block)
        
        attempt = 0
        current_delay = delay
        
        begin
          attempt += 1
          yield
        rescue *retryable_errors => e
          if attempt <= max_retries
            log_retry_attempt(e, attempt, max_retries, current_delay)
            
            sleep(current_delay)
            current_delay = [current_delay * backoff_factor, max_delay].min
            
            retry
          else
            log_retry_exhausted(e, max_retries)
            raise
          end
        end
      end
      
      # Execute block with simple retry (no exponential backoff)
      #
      # @param max_retries [Integer] maximum number of retries
      # @param delay [Numeric] delay between retries
      # @param retryable_errors [Array] list of retryable error classes
      # @yield block to execute with retry
      # @return [Object] result of the block
      def with_simple_retry(max_retries: DEFAULT_RETRY_COUNT,
                           delay: DEFAULT_RETRY_DELAY,
                           retryable_errors: RETRYABLE_ERRORS,
                           &block)
        
        attempt = 0
        
        begin
          attempt += 1
          yield
        rescue *retryable_errors => e
          if attempt <= max_retries
            log_retry_attempt(e, attempt, max_retries, delay)
            
            sleep(delay)
            retry
          else
            log_retry_exhausted(e, max_retries)
            raise
          end
        end
      end
      
      # Execute block with custom retry condition
      #
      # @param max_retries [Integer] maximum number of retries
      # @param delay [Numeric] initial delay between retries
      # @param retry_condition [Proc] custom retry condition
      # @yield block to execute with retry
      # @return [Object] result of the block
      def with_custom_retry(max_retries: DEFAULT_RETRY_COUNT,
                           delay: DEFAULT_RETRY_DELAY,
                           retry_condition: nil,
                           &block)

        attempt = 0
        current_delay = delay

        loop do
          attempt += 1

          begin
            result = yield

            # Check custom retry condition
            if retry_condition && retry_condition.call(result) && attempt <= max_retries
              log_custom_retry_attempt(attempt, max_retries, current_delay)

              sleep(current_delay)
              current_delay *= DEFAULT_BACKOFF_FACTOR

              next  # Continue the loop for retry
            end

            return result
          rescue StandardError => e
            if attempt <= max_retries
              log_retry_attempt(e, attempt, max_retries, current_delay)

              sleep(current_delay)
              current_delay *= DEFAULT_BACKOFF_FACTOR

              next  # Continue the loop for retry
            else
              log_retry_exhausted(e, max_retries)
              raise
            end
          end
        end
      end
      
      # Check if error is retryable
      #
      # @param error [Exception] error to check
      # @param retryable_errors [Array] list of retryable error classes
      # @return [Boolean] true if error is retryable
      def retryable_error?(error, retryable_errors = RETRYABLE_ERRORS)
        retryable_errors.any? { |error_class| error.is_a?(error_class) }
      end
      
      # Calculate delay with jitter
      #
      # @param base_delay [Numeric] base delay
      # @param jitter_factor [Numeric] jitter factor (0.0 to 1.0)
      # @return [Numeric] delay with jitter
      def delay_with_jitter(base_delay, jitter_factor = 0.1)
        jitter = base_delay * jitter_factor * (rand - 0.5) * 2
        base_delay + jitter
      end
      
      private
      
      # Log retry attempt
      #
      # @param error [Exception] error that caused retry
      # @param attempt [Integer] current attempt number
      # @param max_retries [Integer] maximum retries
      # @param delay [Numeric] delay before next attempt
      def log_retry_attempt(error, attempt, max_retries, delay)
        return unless respond_to?(:logger) && logger
        
        logger.warn(
          "Retry attempt #{attempt}/#{max_retries} after error: #{error.class.name}: #{error.message}",
          {
            type: 'retry_attempt',
            attempt: attempt,
            max_retries: max_retries,
            delay: delay,
            error_class: error.class.name,
            error_message: error.message
          }
        )
      end
      
      # Log custom retry attempt
      #
      # @param attempt [Integer] current attempt number
      # @param max_retries [Integer] maximum retries
      # @param delay [Numeric] delay before next attempt
      def log_custom_retry_attempt(attempt, max_retries, delay)
        return unless respond_to?(:logger) && logger
        
        logger.warn(
          "Custom retry attempt #{attempt}/#{max_retries}",
          {
            type: 'custom_retry_attempt',
            attempt: attempt,
            max_retries: max_retries,
            delay: delay
          }
        )
      end
      
      # Log retry exhausted
      #
      # @param error [Exception] final error
      # @param max_retries [Integer] maximum retries attempted
      def log_retry_exhausted(error, max_retries)
        return unless respond_to?(:logger) && logger
        
        logger.error(
          "Retry exhausted after #{max_retries} attempts: #{error.class.name}: #{error.message}",
          {
            type: 'retry_exhausted',
            max_retries: max_retries,
            error_class: error.class.name,
            error_message: error.message
          }
        )
      end
    end
  end
end
