# frozen_string_literal: true

module AliyunEhpc
  module Auth
    # Credentials management for Aliyun API authentication
    class Credentials
      attr_reader :access_key_id, :access_key_secret
      
      def initialize(access_key_id, access_key_secret)
        @access_key_id = access_key_id
        @access_key_secret = access_key_secret
        
        validate!
      end
      
      # Create credentials from configuration
      #
      # @param config [Configuration] configuration object
      # @return [Credentials] credentials instance
      def self.from_config(config)
        new(config.access_key_id, config.access_key_secret)
      end
      
      # Create credentials from environment variables
      #
      # @return [Credentials] credentials instance
      def self.from_env
        access_key_id = ENV['ALIYUN_ACCESS_KEY_ID']
        access_key_secret = ENV['ALIYUN_ACCESS_KEY_SECRET']
        
        raise AuthenticationError, 'ALIYUN_ACCESS_KEY_ID environment variable not set' unless access_key_id
        raise AuthenticationError, 'ALIYUN_ACCESS_KEY_SECRET environment variable not set' unless access_key_secret
        
        new(access_key_id, access_key_secret)
      end
      
      # Check if credentials are valid
      #
      # @return [Boolean] true if valid
      def valid?
        !access_key_id.nil? && !access_key_secret.nil? &&
          !access_key_id.empty? && !access_key_secret.empty?
      end
      
      # Get credentials as hash (with secret redacted)
      #
      # @return [Hash] credentials hash
      def to_h
        {
          access_key_id: access_key_id,
          access_key_secret: '[REDACTED]'
        }
      end
      
      # Compare credentials (constant time comparison for security)
      #
      # @param other [Credentials] other credentials object
      # @return [Boolean] true if equal
      def ==(other)
        return false unless other.is_a?(Credentials)
        
        secure_compare(access_key_id, other.access_key_id) &&
          secure_compare(access_key_secret, other.access_key_secret)
      end
      
      private
      
      # Validate credentials
      def validate!
        raise AuthenticationError, 'access_key_id cannot be nil or empty' unless access_key_id && !access_key_id.empty?
        raise AuthenticationError, 'access_key_secret cannot be nil or empty' unless access_key_secret && !access_key_secret.empty?
        
        # Basic format validation
        unless access_key_id.match?(/^[A-Za-z0-9]+$/)
          raise AuthenticationError, 'access_key_id contains invalid characters'
        end
        
        unless access_key_secret.match?(/^[A-Za-z0-9+\/=]+$/)
          raise AuthenticationError, 'access_key_secret contains invalid characters'
        end
        
        # Length validation
        if access_key_id.length < 16 || access_key_id.length > 32
          raise AuthenticationError, 'access_key_id length must be between 16 and 32 characters'
        end
        
        if access_key_secret.length < 28 || access_key_secret.length > 44
          raise AuthenticationError, 'access_key_secret length must be between 28 and 44 characters'
        end
      end
      
      # Secure string comparison to prevent timing attacks
      #
      # @param a [String] first string
      # @param b [String] second string
      # @return [Boolean] true if equal
      def secure_compare(a, b)
        return false unless a.bytesize == b.bytesize
        
        result = 0
        a.bytes.zip(b.bytes) { |x, y| result |= x ^ y }
        result == 0
      end
    end
  end
end
