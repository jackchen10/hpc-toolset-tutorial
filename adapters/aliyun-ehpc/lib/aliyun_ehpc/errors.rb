# frozen_string_literal: true

module AliyunEhpc
  # Base error class for all AliyunEhpc errors
  class Error < StandardError
    attr_reader :code, :request_id, :details
    
    def initialize(message = nil, code: nil, request_id: nil, details: nil)
      super(message)
      @code = code
      @request_id = request_id
      @details = details
    end
    
    def to_h
      {
        error: self.class.name,
        message: message,
        code: code,
        request_id: request_id,
        details: details
      }.compact
    end
  end
  
  # Configuration related errors
  class ConfigurationError < Error; end
  
  # Authentication related errors
  class AuthenticationError < Error; end
  
  # API related errors
  class APIError < Error; end
  
  # Network related errors
  class NetworkError < Error; end
  
  # Timeout errors
  class TimeoutError < NetworkError; end
  
  # Rate limit errors
  class RateLimitError < APIError; end
  
  # Resource not found errors
  class NotFoundError < APIError; end
  
  # Permission denied errors
  class PermissionError < APIError; end
  
  # Validation errors
  class ValidationError < Error; end
  
  # Cluster related errors
  class ClusterError < APIError; end
  
  # Job related errors
  class JobError < APIError; end
  
  # User related errors
  class UserError < APIError; end
  
  # Queue related errors
  class QueueError < APIError; end
  
  # OnDemand adapter errors
  class AdapterError < Error; end
  
  # Script parsing errors
  class ScriptParsingError < Error; end
end
