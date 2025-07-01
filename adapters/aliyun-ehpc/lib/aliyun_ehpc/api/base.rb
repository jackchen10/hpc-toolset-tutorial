# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

module AliyunEhpc
  module API
    # Base API client class
    class Base
      include Utils::Retry
      include Utils::Validator
      
      attr_reader :auth, :config, :http_client
      
      def initialize(auth_manager, configuration)
        @auth = auth_manager
        @config = configuration
        @http_client = build_http_client
        @logger = Utils::Logger.new(config.log_level)
      end
      
      protected
      
      # Make API request with authentication and error handling
      #
      # @param action [String] API action name
      # @param params [Hash] request parameters
      # @param options [Hash] request options
      # @return [Hash] parsed response data
      def make_request(action, params = {}, options = {})
        # Prepare request parameters
        request_params = prepare_request_params(action, params)

        # Get HTTP method from options
        http_method = options[:method] || 'POST'

        # Sign the request
        signed_params = @auth.sign_request(http_method, request_params)
        
        # Make HTTP request with retry
        response_data = with_retry(
          max_retries: @config.retry_count,
          delay: @config.retry_delay
        ) do
          execute_http_request(signed_params, options)
        end
        
        # Parse and validate response
        parse_response(response_data)
      end
      
      # Make GET request
      #
      # @param action [String] API action name
      # @param params [Hash] request parameters
      # @param options [Hash] request options
      # @return [Hash] parsed response data
      def get(action, params = {}, options = {})
        make_request(action, params, options.merge(method: 'GET'))
      end
      
      # Make POST request
      #
      # @param action [String] API action name
      # @param params [Hash] request parameters
      # @param options [Hash] request options
      # @return [Hash] parsed response data
      def post(action, params = {}, options = {})
        make_request(action, params, options.merge(method: 'POST'))
      end
      
      # Handle paginated requests
      #
      # @param action [String] API action name
      # @param params [Hash] request parameters
      # @param options [Hash] pagination options
      # @yield [Hash] each page of results
      # @return [Array] all results if no block given
      def paginate(action, params = {}, options = {})
        page_size = options[:page_size] || 50
        max_pages = options[:max_pages] || 100
        results = []
        page_number = 1
        
        loop do
          page_params = params.merge(
            'PageSize' => page_size,
            'PageNumber' => page_number
          )
          
          response = make_request(action, page_params)
          page_results = extract_page_results(response, options)
          
          if block_given?
            yield page_results
          else
            results.concat(page_results)
          end
          
          # Check if we should continue pagination
          break unless should_continue_pagination?(response, page_number, max_pages)
          
          page_number += 1
        end
        
        block_given? ? nil : results
      end
      
      private
      
      # Build HTTP client
      #
      # @return [Net::HTTP] configured HTTP client
      def build_http_client
        uri = URI(@config.endpoint_url)
        http = Net::HTTP.new(uri.host, uri.port)
        
        # Configure SSL
        if uri.scheme == 'https'
          http.use_ssl = true
          http.verify_mode = @config.ssl_verify ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
        end
        
        # Configure timeouts
        http.open_timeout = @config.timeout
        http.read_timeout = @config.timeout
        http.write_timeout = @config.timeout if http.respond_to?(:write_timeout=)
        
        # Configure proxy if specified
        if @config.proxy_host
          http = Net::HTTP.new(
            uri.host, uri.port,
            @config.proxy_host, @config.proxy_port,
            @config.proxy_user, @config.proxy_pass
          )
        end
        
        http
      end
      
      # Prepare request parameters with common fields
      #
      # @param action [String] API action name
      # @param params [Hash] request parameters
      # @return [Hash] prepared parameters
      def prepare_request_params(action, params)
        common_params = {
          'Action' => action,
          'Version' => @config.api_version,
          'Format' => 'JSON',
          'RegionId' => @config.region
        }
        
        common_params.merge(params)
      end
      
      # Execute HTTP request
      #
      # @param params [Hash] signed request parameters
      # @param options [Hash] request options
      # @return [String] response body
      def execute_http_request(params, options = {})
        method = options[:method] || 'POST'
        start_time = Time.now
        
        begin
          case method.upcase
          when 'GET'
            response = execute_get_request(params)
          when 'POST'
            response = execute_post_request(params)
          else
            raise ArgumentError, "Unsupported HTTP method: #{method}"
          end
          
          duration = Time.now - start_time
          
          # Log request and response
          @logger.debug("API request completed", {
            method: method,
            url: @config.endpoint_url,
            duration: duration,
            response_code: response.code.to_i,
            response_size: response.body.bytesize
          })
          
          # Handle HTTP errors
          handle_http_response(response)
          
          response.body
        rescue StandardError => e
          duration = Time.now - start_time
          @logger.error("HTTP request failed: #{e.message}", {
            method: method,
            url: @config.endpoint_url,
            duration: duration,
            error_class: e.class.name
          })
          raise
        end
      end
      
      # Execute GET request
      #
      # @param params [Hash] request parameters
      # @return [Net::HTTPResponse] HTTP response
      def execute_get_request(params)
        query_string = URI.encode_www_form(params)
        uri = URI(@config.endpoint_url)
        uri.path = '/' if uri.path.empty?
        uri.query = query_string

        request = Net::HTTP::Get.new(uri)
        add_common_headers(request)

        @http_client.request(request)
      end
      
      # Execute POST request
      #
      # @param params [Hash] request parameters
      # @return [Net::HTTPResponse] HTTP response
      def execute_post_request(params)
        uri = URI(@config.endpoint_url)
        uri.path = '/' if uri.path.empty?
        request = Net::HTTP::Post.new(uri)

        add_common_headers(request)
        request['Content-Type'] = 'application/x-www-form-urlencoded'
        request.body = URI.encode_www_form(params)

        @http_client.request(request)
      end
      
      # Add common headers to request
      #
      # @param request [Net::HTTPRequest] HTTP request
      def add_common_headers(request)
        request['User-Agent'] = "AliyunEhpc-Ruby/#{AliyunEhpc::VERSION}"
        request['Accept'] = 'application/json'
        request['Accept-Encoding'] = 'gzip, deflate'
      end
      
      # Handle HTTP response and check for errors
      #
      # @param response [Net::HTTPResponse] HTTP response
      # @return [Net::HTTPResponse] response if successful
      def handle_http_response(response)
        case response.code.to_i
        when 200..299
          response
        when 400..499
          handle_client_error(response)
        when 500..599
          handle_server_error(response)
        else
          raise NetworkError, "Unexpected HTTP status: #{response.code}"
        end
      end
      
      # Handle client errors (4xx)
      #
      # @param response [Net::HTTPResponse] HTTP response
      def handle_client_error(response)
        error_data = parse_error_response(response.body)
        error_code = error_data['Code'] || error_data[:code]
        error_message = error_data['Message'] || error_data[:message] || "Client error: #{response.code}"

        # Handle specific Aliyun error codes
        case error_code
        when 'EntityNotExist.Role', 'Forbidden.RAM'
          raise PermissionError.new(error_message,
                                   code: error_code,
                                   request_id: error_data['RequestId'])
        when 'InvalidAction.NotFound'
          raise NotFoundError.new(error_message,
                                 code: error_code,
                                 request_id: error_data['RequestId'])
        when 'SignatureDoesNotMatch', 'InvalidAccessKeyId.NotFound'
          raise AuthenticationError.new(error_message,
                                       code: error_code,
                                       request_id: error_data['RequestId'])
        else
          # Fall back to HTTP status code
          case response.code.to_i
          when 401
            raise AuthenticationError.new(error_message,
                                         code: error_code,
                                         request_id: error_data['RequestId'])
          when 403
            raise PermissionError.new(error_message,
                                     code: error_code,
                                     request_id: error_data['RequestId'])
          when 404
            raise NotFoundError.new(error_message,
                                   code: error_code,
                                   request_id: error_data['RequestId'])
          when 429
            raise RateLimitError.new(error_message,
                                    code: error_code,
                                    request_id: error_data['RequestId'])
          else
            raise APIError.new(error_message,
                              code: error_code,
                              request_id: error_data['RequestId'])
          end
        end
      end
      
      # Handle server errors (5xx)
      #
      # @param response [Net::HTTPResponse] HTTP response
      def handle_server_error(response)
        error_data = parse_error_response(response.body)
        raise APIError, error_data[:message] || "Server error: #{response.code}"
      end
      
      # Parse error response
      #
      # @param body [String] response body
      # @return [Hash] parsed error data
      def parse_error_response(body)
        JSON.parse(body)
      rescue JSON::ParserError
        { message: body }
      end
      
      # Parse successful response
      #
      # @param body [String] response body
      # @return [Hash] parsed response data
      def parse_response(body)
        data = JSON.parse(body)
        
        # Check for API-level errors
        if data['Code'] && data['Code'] != 'Success'
          raise APIError.new(
            data['Message'] || 'API error',
            code: data['Code'],
            request_id: data['RequestId']
          )
        end
        
        data
      rescue JSON::ParserError => e
        raise APIError, "Invalid JSON response: #{e.message}"
      end
      
      # Extract results from paginated response
      #
      # @param response [Hash] API response
      # @param options [Hash] extraction options
      # @return [Array] page results
      def extract_page_results(response, options = {})
        results_key = options[:results_key] || 'Items'
        response[results_key] || []
      end
      
      # Check if pagination should continue
      #
      # @param response [Hash] API response
      # @param current_page [Integer] current page number
      # @param max_pages [Integer] maximum pages to fetch
      # @return [Boolean] true if should continue
      def should_continue_pagination?(response, current_page, max_pages)
        return false if current_page >= max_pages
        
        total_count = response['TotalCount']
        page_size = response['PageSize']
        page_number = response['PageNumber']
        
        return false unless total_count && page_size && page_number
        
        total_pages = (total_count.to_f / page_size).ceil
        page_number < total_pages
      end
    end
  end
end
