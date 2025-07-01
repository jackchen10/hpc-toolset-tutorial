# frozen_string_literal: true

module AliyunEhpc
  module Models
    # Base model class for all E-HPC models
    class Base
      include Utils::Validator
      
      attr_reader :attributes, :raw_data
      
      def initialize(attributes = {})
        @attributes = {}
        @raw_data = attributes.dup
        
        # Set attributes through setters for validation
        attributes.each do |key, value|
          setter_method = "#{key}="
          if respond_to?(setter_method, true)
            send(setter_method, value)
          else
            @attributes[key.to_sym] = value
          end
        end
        
        # Validate after initialization
        validate! if respond_to?(:validate!, true)
      end
      
      # Get attribute value
      #
      # @param key [Symbol, String] attribute key
      # @return [Object] attribute value
      def [](key)
        @attributes[key.to_sym]
      end
      
      # Set attribute value
      #
      # @param key [Symbol, String] attribute key
      # @param value [Object] attribute value
      def []=(key, value)
        @attributes[key.to_sym] = value
      end
      
      # Check if attribute exists
      #
      # @param key [Symbol, String] attribute key
      # @return [Boolean] true if attribute exists
      def key?(key)
        @attributes.key?(key.to_sym)
      end
      
      # Get all attribute keys
      #
      # @return [Array<Symbol>] attribute keys
      def keys
        @attributes.keys
      end
      
      # Get all attribute values
      #
      # @return [Array] attribute values
      def values
        @attributes.values
      end
      
      # Convert to hash
      #
      # @return [Hash] model as hash
      def to_h
        @attributes.dup
      end
      
      # Convert to JSON
      #
      # @return [String] model as JSON string
      def to_json(*args)
        JSON.generate(to_h, *args)
      end
      
      # Check if model is equal to another model
      #
      # @param other [Base] other model
      # @return [Boolean] true if equal
      def ==(other)
        return false unless other.is_a?(self.class)
        
        @attributes == other.attributes
      end
      
      # Get model hash code
      #
      # @return [Integer] hash code
      def hash
        [@attributes, self.class].hash
      end
      
      # Check if model is equal (alias for ==)
      alias eql? ==
      
      # String representation
      #
      # @return [String] string representation
      def to_s
        "#<#{self.class.name}:#{object_id} #{@attributes.inspect}>"
      end
      
      # Detailed inspection
      #
      # @return [String] detailed inspection
      def inspect
        to_s
      end
      
      # Update attributes
      #
      # @param new_attributes [Hash] new attributes
      # @return [self] updated model
      def update(new_attributes)
        new_attributes.each do |key, value|
          setter_method = "#{key}="
          if respond_to?(setter_method, true)
            send(setter_method, value)
          else
            @attributes[key.to_sym] = value
          end
        end
        
        validate! if respond_to?(:validate!, true)
        self
      end
      
      # Merge with another model or hash
      #
      # @param other [Base, Hash] other model or hash
      # @return [Base] new merged model
      def merge(other)
        other_attributes = other.is_a?(Base) ? other.attributes : other
        self.class.new(@attributes.merge(other_attributes))
      end
      
      # Check if model has changes from original data
      #
      # @return [Boolean] true if model has changes
      def changed?
        @attributes != normalize_hash(@raw_data)
      end
      
      # Get changed attributes
      #
      # @return [Hash] changed attributes
      def changes
        original = normalize_hash(@raw_data)
        current = @attributes
        
        changes = {}
        
        # Find modified and new attributes
        current.each do |key, value|
          if !original.key?(key) || original[key] != value
            changes[key] = [original[key], value]
          end
        end
        
        # Find removed attributes
        original.each do |key, value|
          unless current.key?(key)
            changes[key] = [value, nil]
          end
        end
        
        changes
      end
      
      # Reset to original state
      #
      # @return [self] reset model
      def reset!
        @attributes = normalize_hash(@raw_data)
        self
      end
      
      # Create a copy of the model
      #
      # @return [Base] copied model
      def dup
        self.class.new(@attributes)
      end
      
      # Create a deep copy of the model
      #
      # @return [Base] deep copied model
      def deep_dup
        require 'deep_dup' if defined?(Rails)
        
        if respond_to?(:deep_dup)
          self.class.new(@attributes.deep_dup)
        else
          # Fallback to Marshal for deep copy
          self.class.new(Marshal.load(Marshal.dump(@attributes)))
        end
      end
      
      protected
      
      # Define attribute accessor
      #
      # @param name [Symbol] attribute name
      # @param type [Class] expected type (optional)
      # @param default [Object] default value (optional)
      def self.attribute(name, type: nil, default: nil)
        # Getter method
        define_method(name) do
          @attributes[name] || default
        end
        
        # Setter method
        define_method("#{name}=") do |value|
          if type && !value.nil? && !value.is_a?(type)
            raise ValidationError, "#{name} must be of type #{type}, got #{value.class}"
          end
          
          @attributes[name] = value
        end
      end
      
      private
      
      # Normalize hash keys to symbols
      #
      # @param hash [Hash] hash to normalize
      # @return [Hash] normalized hash
      def normalize_hash(hash)
        return {} unless hash.is_a?(Hash)
        
        normalized = {}
        hash.each do |key, value|
          normalized[key.to_sym] = value
        end
        normalized
      end
    end
  end
end
