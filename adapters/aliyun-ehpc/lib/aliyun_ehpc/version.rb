# frozen_string_literal: true

module AliyunEhpc
  # Gem version
  VERSION = '1.0.0'
  
  # API version supported
  API_VERSION = '2018-04-12'
  
  # Build information
  BUILD_INFO = {
    version: VERSION,
    api_version: API_VERSION,
    build_date: Time.now.strftime('%Y-%m-%d'),
    ruby_version: RUBY_VERSION,
    platform: RUBY_PLATFORM
  }.freeze
  
  # Version information as string
  #
  # @return [String] formatted version string
  def self.version_string
    "AliyunEhpc v#{VERSION} (API v#{API_VERSION})"
  end
  
  # Full build information
  #
  # @return [Hash] build information hash
  def self.build_info
    BUILD_INFO
  end
end
