# frozen_string_literal: true

require_relative 'lib/aliyun_ehpc/version'

Gem::Specification.new do |spec|
  spec.name = 'aliyun_ehpc'
  spec.version = AliyunEhpc::VERSION
  spec.authors = ['HPC Toolset Tutorial Project']
  spec.email = ['hpc-toolset@example.com']

  spec.summary = 'Ruby SDK for Alibaba Cloud E-HPC service'
  spec.description = 'A comprehensive Ruby SDK for Alibaba Cloud Elastic High Performance Computing (E-HPC) service with Open OnDemand integration support.'
  spec.homepage = 'https://github.com/jackchen10/hpc-toolset-tutorial'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/jackchen10/hpc-toolset-tutorial'
  spec.metadata['changelog_uri'] = 'https://github.com/jackchen10/hpc-toolset-tutorial/blob/main/adapters/aliyun-ehpc/CHANGELOG.md'
  spec.metadata['documentation_uri'] = 'https://github.com/jackchen10/hpc-toolset-tutorial/tree/main/adapters/aliyun-ehpc/docs'

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'json', '~> 2.6'
  spec.add_dependency 'net-http', '~> 0.3'
  
  # Development dependencies
  spec.add_development_dependency 'bundler', '~> 2.4'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'webmock', '~> 3.18'
  spec.add_development_dependency 'vcr', '~> 6.1'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'rubocop', '~> 1.50'
  spec.add_development_dependency 'yard', '~> 0.9'
end
