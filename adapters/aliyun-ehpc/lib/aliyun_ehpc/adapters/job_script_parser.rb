# frozen_string_literal: true

module AliyunEhpc
  module Adapters
    # SLURM job script parser for converting to E-HPC job configuration
    class JobScriptParser
      include Utils::Validator
      
      attr_reader :config
      
      # SLURM directive patterns
      SLURM_DIRECTIVES = {
        job_name: /^#SBATCH\s+(?:--job-name=|--job-name\s+|--J\s+|--J=)(.+)$/,
        partition: /^#SBATCH\s+(?:--partition=|--partition\s+|--p\s+|--p=)(.+)$/,
        nodes: /^#SBATCH\s+(?:--nodes=|--nodes\s+|--N\s+|--N=)(\d+)$/,
        ntasks: /^#SBATCH\s+(?:--ntasks=|--ntasks\s+|--n\s+|--n=)(\d+)$/,
        ntasks_per_node: /^#SBATCH\s+(?:--ntasks-per-node=|--ntasks-per-node\s+)(\d+)$/,
        cpus_per_task: /^#SBATCH\s+(?:--cpus-per-task=|--cpus-per-task\s+|--c\s+|--c=)(\d+)$/,
        memory: /^#SBATCH\s+(?:--mem=|--mem\s+)(\d+)([KMG]?)$/,
        memory_per_cpu: /^#SBATCH\s+(?:--mem-per-cpu=|--mem-per-cpu\s+)(\d+)([KMG]?)$/,
        time: /^#SBATCH\s+(?:--time=|--time\s+|--t\s+|--t=)(.+)$/,
        output: /^#SBATCH\s+(?:--output=|--output\s+|--o\s+|--o=)(.+)$/,
        error: /^#SBATCH\s+(?:--error=|--error\s+|--e\s+|--e=)(.+)$/,
        workdir: /^#SBATCH\s+(?:--chdir=|--chdir\s+|--workdir=|--workdir\s+|--D\s+|--D=)(.+)$/,
        array: /^#SBATCH\s+(?:--array=|--array\s+|--a\s+|--a=)(.+)$/,
        dependency: /^#SBATCH\s+(?:--dependency=|--dependency\s+|--d\s+|--d=)(.+)$/,
        gres: /^#SBATCH\s+(?:--gres=|--gres\s+)(.+)$/,
        constraint: /^#SBATCH\s+(?:--constraint=|--constraint\s+|--C\s+|--C=)(.+)$/,
        exclusive: /^#SBATCH\s+(?:--exclusive)$/,
        mail_type: /^#SBATCH\s+(?:--mail-type=|--mail-type\s+)(.+)$/,
        mail_user: /^#SBATCH\s+(?:--mail-user=|--mail-user\s+)(.+)$/,
        account: /^#SBATCH\s+(?:--account=|--account\s+|--A\s+|--A=)(.+)$/,
        qos: /^#SBATCH\s+(?:--qos=|--qos\s+|--q\s+|--q=)(.+)$/
      }.freeze
      
      def initialize(options = {})
        @config = {
          default_queue: 'normal',
          default_memory_mb: 1024,
          default_walltime: 3600,
          default_cores: 1,
          user_mapping: {},
          queue_mapping: {},
          resource_mapping: {}
        }.merge(options)
      end
      
      # Parse SLURM script and convert to E-HPC job configuration
      #
      # @param script_content [String] SLURM script content
      # @return [Hash] E-HPC job configuration
      def parse(script_content)
        raise ScriptParsingError, 'Script content cannot be empty' if script_content.nil? || script_content.empty?
        
        # Parse SLURM directives
        directives = parse_slurm_directives(script_content)
        
        # Extract command lines
        command_lines = extract_command_lines(script_content)
        
        # Build E-HPC job configuration
        build_ehpc_job_config(directives, command_lines)
      end
      
      # Validate SLURM script syntax
      #
      # @param script_content [String] SLURM script content
      # @return [Array<String>] list of validation errors
      def validate_script(script_content)
        errors = []
        
        return ['Script content cannot be empty'] if script_content.nil? || script_content.empty?
        
        lines = script_content.split("\n")
        
        # Check for shebang
        unless lines.first&.start_with?('#!')
          errors << 'Script should start with a shebang (e.g., #!/bin/bash)'
        end
        
        # Check for required directives
        has_job_name = script_content.match?(SLURM_DIRECTIVES[:job_name])
        errors << 'Job name is required (--job-name)' unless has_job_name
        
        # Check for command lines
        command_lines = extract_command_lines(script_content)
        errors << 'Script must contain executable commands' if command_lines.empty?
        
        # Validate directive syntax
        lines.each_with_index do |line, index|
          next unless line.start_with?('#SBATCH')
          
          # Check if directive is recognized
          recognized = SLURM_DIRECTIVES.values.any? { |pattern| line.match?(pattern) }
          unless recognized
            errors << "Unrecognized SLURM directive at line #{index + 1}: #{line}"
          end
        end
        
        errors
      end
      
      # Get supported SLURM directives
      #
      # @return [Array<Symbol>] list of supported directive names
      def supported_directives
        SLURM_DIRECTIVES.keys
      end
      
      # Convert time string to seconds
      #
      # @param time_str [String] time string (e.g., "1:30:00", "90", "1-12:30:00")
      # @return [Integer] time in seconds
      def parse_time_string(time_str)
        return nil if time_str.nil? || time_str.empty?
        
        # Handle different time formats
        case time_str
        when /^(\d+)$/ # Just minutes
          $1.to_i * 60
        when /^(\d+):(\d+)$/ # MM:SS or HH:MM
          $1.to_i * 3600 + $2.to_i * 60
        when /^(\d+):(\d+):(\d+)$/ # HH:MM:SS
          $1.to_i * 3600 + $2.to_i * 60 + $3.to_i
        when /^(\d+)-(\d+):(\d+):(\d+)$/ # DD-HH:MM:SS
          $1.to_i * 86400 + $2.to_i * 3600 + $3.to_i * 60 + $4.to_i
        when /^(\d+)-(\d+):(\d+)$/ # DD-HH:MM
          $1.to_i * 86400 + $2.to_i * 3600 + $3.to_i * 60
        when /^(\d+)-(\d+)$/ # DD-HH
          $1.to_i * 86400 + $2.to_i * 3600
        else
          raise ScriptParsingError, "Invalid time format: #{time_str}"
        end
      end
      
      # Convert memory string to MB
      #
      # @param memory_str [String] memory string (e.g., "1024", "1G", "512M")
      # @return [Integer] memory in MB
      def parse_memory_string(memory_str)
        return nil if memory_str.nil? || memory_str.empty?
        
        if memory_str.match?(/^(\d+)([KMG]?)$/)
          value = $1.to_i
          unit = $2.upcase
          
          case unit
          when 'K'
            (value / 1024.0).ceil
          when 'M', ''
            value
          when 'G'
            value * 1024
          else
            raise ScriptParsingError, "Invalid memory unit: #{unit}"
          end
        else
          raise ScriptParsingError, "Invalid memory format: #{memory_str}"
        end
      end
      
      private
      
      # Parse SLURM directives from script
      #
      # @param script_content [String] script content
      # @return [Hash] parsed directives
      def parse_slurm_directives(script_content)
        directives = {}
        
        script_content.split("\n").each do |line|
          line = line.strip
          next unless line.start_with?('#SBATCH')
          
          SLURM_DIRECTIVES.each do |name, pattern|
            if (match = line.match(pattern))
              directives[name] = match[1].strip
              break
            end
          end
        end
        
        directives
      end
      
      # Extract command lines from script
      #
      # @param script_content [String] script content
      # @return [Array<String>] command lines
      def extract_command_lines(script_content)
        lines = script_content.split("\n")
        command_lines = []
        
        lines.each do |line|
          line = line.strip
          
          # Skip empty lines, comments, and SLURM directives
          next if line.empty?
          next if line.start_with?('#') && !line.start_with?('#!')
          next if line.start_with?('#!')
          
          command_lines << line
        end
        
        command_lines
      end
      
      # Build E-HPC job configuration from parsed data
      #
      # @param directives [Hash] parsed SLURM directives
      # @param command_lines [Array<String>] command lines
      # @return [Hash] E-HPC job configuration
      def build_ehpc_job_config(directives, command_lines)
        config = {}
        
        # Basic job information
        config['Name'] = directives[:job_name] || 'unnamed_job'
        config['CommandLine'] = command_lines.join(' && ')
        
        # Queue/partition mapping
        if directives[:partition]
          config['JobQueue'] = map_queue_name(directives[:partition])
        else
          config['JobQueue'] = @config[:default_queue]
        end
        
        # Working directory
        config['WorkingDir'] = directives[:workdir] if directives[:workdir]
        
        # Output files
        config['StdoutRedirectPath'] = directives[:output] if directives[:output]
        config['StderrRedirectPath'] = directives[:error] if directives[:error]
        
        # Resource requirements
        add_resource_requirements(config, directives)
        
        # Time limit
        if directives[:time]
          config['ClockTime'] = parse_time_string(directives[:time])
        else
          config['ClockTime'] = @config[:default_walltime]
        end
        
        # Array job
        config['ArrayRequest'] = directives[:array] if directives[:array]
        
        # Dependencies
        config['Dependencies'] = parse_dependencies(directives[:dependency]) if directives[:dependency]
        
        # GPU requirements
        add_gpu_requirements(config, directives)
        
        # Additional options
        add_additional_options(config, directives)
        
        config
      end
      
      # Add resource requirements to job config
      #
      # @param config [Hash] job configuration
      # @param directives [Hash] parsed directives
      def add_resource_requirements(config, directives)
        # Node count
        config['Node'] = directives[:nodes].to_i if directives[:nodes]
        
        # Task count
        if directives[:ntasks]
          config['Task'] = directives[:ntasks].to_i
        elsif directives[:ntasks_per_node] && directives[:nodes]
          config['Task'] = directives[:ntasks_per_node].to_i * directives[:nodes].to_i
        end
        
        # CPU count
        if directives[:cpus_per_task]
          config['Thread'] = directives[:cpus_per_task].to_i
        else
          config['Thread'] = @config[:default_cores]
        end
        
        # Memory requirements
        add_memory_requirements(config, directives)
      end
      
      # Add memory requirements to job config
      #
      # @param config [Hash] job configuration
      # @param directives [Hash] parsed directives
      def add_memory_requirements(config, directives)
        memory_mb = nil
        
        if directives[:memory]
          memory_mb = parse_memory_string(directives[:memory])
        elsif directives[:memory_per_cpu]
          per_cpu_mb = parse_memory_string(directives[:memory_per_cpu])
          cpu_count = config['Thread'] || @config[:default_cores]
          memory_mb = per_cpu_mb * cpu_count
        else
          memory_mb = @config[:default_memory_mb]
        end
        
        config['MemSize'] = memory_mb if memory_mb
      end
      
      # Add GPU requirements to job config
      #
      # @param config [Hash] job configuration
      # @param directives [Hash] parsed directives
      def add_gpu_requirements(config, directives)
        return unless directives[:gres]
        
        # Parse GPU requirements from gres directive
        if directives[:gres].match?(/gpu:(\d+)/)
          config['Gpu'] = $1.to_i
        elsif directives[:gres].match?(/gpu:([^:]+):(\d+)/)
          # GPU type and count
          config['Gpu'] = $2.to_i
          config['GpuType'] = $1
        end
      end
      
      # Add additional options to job config
      #
      # @param config [Hash] job configuration
      # @param directives [Hash] parsed directives
      def add_additional_options(config, directives)
        # Account/project
        config['AccountingId'] = directives[:account] if directives[:account]
        
        # QoS
        config['QoS'] = directives[:qos] if directives[:qos]
        
        # Constraints
        config['Constraints'] = directives[:constraint] if directives[:constraint]
        
        # Exclusive node access
        config['Exclusive'] = true if directives[:exclusive]
        
        # Email notifications
        if directives[:mail_type] && directives[:mail_user]
          config['MailType'] = directives[:mail_type]
          config['MailUser'] = directives[:mail_user]
        end
      end
      
      # Parse job dependencies
      #
      # @param dependency_str [String] dependency string
      # @return [Array<String>] parsed dependencies
      def parse_dependencies(dependency_str)
        dependencies = []
        
        dependency_str.split(',').each do |dep|
          dep = dep.strip
          
          case dep
          when /^afterok:(.+)$/
            dependencies << "afterok:#{$1}"
          when /^afternotok:(.+)$/
            dependencies << "afternotok:#{$1}"
          when /^afterany:(.+)$/
            dependencies << "afterany:#{$1}"
          when /^after:(.+)$/
            dependencies << "afterok:#{$1}"
          else
            # Default to afterok
            dependencies << "afterok:#{dep}"
          end
        end
        
        dependencies
      end
      
      # Map SLURM queue name to E-HPC queue name
      #
      # @param slurm_queue [String] SLURM queue name
      # @return [String] E-HPC queue name
      def map_queue_name(slurm_queue)
        @config[:queue_mapping][slurm_queue] || slurm_queue
      end
    end
  end
end
