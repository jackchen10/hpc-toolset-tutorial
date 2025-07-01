# frozen_string_literal: true

require 'openssl'
require 'base64'
require 'uri'
require 'cgi'

module AliyunEhpc
  module Auth
    # Aliyun API signature generation
    class Signature
      attr_reader :credentials
      
      def initialize(credentials)
        @credentials = credentials
      end
      
      # Sign a request with Aliyun signature algorithm
      #
      # @param http_method [String] HTTP method (GET, POST, etc.)
      # @param params [Hash] request parameters
      # @param headers [Hash] request headers (optional)
      # @return [Hash] signed parameters including signature
      def sign_request(http_method, params = {}, headers = {})
        # Add common parameters
        signed_params = add_common_params(params)
        
        # Generate signature
        signature = generate_signature(http_method, signed_params)
        
        # Add signature to parameters
        signed_params['Signature'] = signature
        
        signed_params
      end
      
      # Generate signature for the request
      #
      # @param http_method [String] HTTP method
      # @param params [Hash] request parameters
      # @return [String] base64 encoded signature
      def generate_signature(http_method, params)
        # Create canonical query string
        canonical_query_string = create_canonical_query_string(params)
        
        # Create string to sign
        string_to_sign = create_string_to_sign(http_method, canonical_query_string)
        
        # Generate HMAC-SHA1 signature
        hmac = OpenSSL::HMAC.digest('sha1', "#{credentials.access_key_secret}&", string_to_sign)
        
        # Base64 encode the signature
        Base64.strict_encode64(hmac)
      end
      
      # Verify signature for incoming requests (for webhook validation)
      #
      # @param http_method [String] HTTP method
      # @param params [Hash] request parameters
      # @param expected_signature [String] expected signature
      # @return [Boolean] true if signature is valid
      def verify_signature(http_method, params, expected_signature)
        # Remove signature from params for verification
        params_without_signature = params.dup
        params_without_signature.delete('Signature')
        
        # Generate signature
        calculated_signature = generate_signature(http_method, params_without_signature)
        
        # Secure comparison
        secure_compare(calculated_signature, expected_signature)
      end
      
      private
      
      # Add common parameters required for Aliyun API
      #
      # @param params [Hash] original parameters
      # @return [Hash] parameters with common fields added
      def add_common_params(params)
        common_params = {
          'AccessKeyId' => credentials.access_key_id,
          'SignatureMethod' => 'HMAC-SHA1',
          'SignatureVersion' => '1.0',
          'SignatureNonce' => generate_nonce,
          'Timestamp' => generate_timestamp,
          'Version' => '2018-04-12',
          'Format' => 'JSON'
        }
        
        # Merge with provided parameters
        common_params.merge(params)
      end
      
      # Create canonical query string for signature
      #
      # @param params [Hash] request parameters
      # @return [String] canonical query string
      def create_canonical_query_string(params)
        # Sort parameters by key
        sorted_params = params.sort
        
        # URL encode and join parameters
        encoded_params = sorted_params.map do |key, value|
          "#{percent_encode(key.to_s)}=#{percent_encode(value.to_s)}"
        end
        
        encoded_params.join('&')
      end
      
      # Create string to sign according to Aliyun specification
      #
      # @param http_method [String] HTTP method
      # @param canonical_query_string [String] canonical query string
      # @return [String] string to sign
      def create_string_to_sign(http_method, canonical_query_string)
        [
          http_method.upcase,
          percent_encode('/'),
          percent_encode(canonical_query_string)
        ].join('&')
      end
      
      # Percent encode according to RFC 3986
      #
      # @param string [String] string to encode
      # @return [String] percent encoded string
      def percent_encode(string)
        CGI.escape(string.to_s)
           .gsub('+', '%20')
           .gsub('*', '%2A')
           .gsub('%7E', '~')
      end
      
      # Generate unique nonce for request
      #
      # @return [String] unique nonce
      def generate_nonce
        SecureRandom.uuid.delete('-')
      end
      
      # Generate ISO8601 timestamp
      #
      # @return [String] ISO8601 formatted timestamp
      def generate_timestamp
        Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
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
