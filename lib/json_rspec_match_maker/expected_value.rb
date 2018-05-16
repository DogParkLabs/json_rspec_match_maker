# frozen_string_literal: true

module JsonRspecMatchMaker
  # Handles fetching the expected value from the expected instance
  class ExpectedValue
    attr_reader :value
    def initialize(match_function, expected_instance, error_key, prefix)
      @value = fetch_expected_value(expected_instance, match_function, error_key, prefix)
    end

    # Checks equality against a TargetValue
    # @raise [ArgumentError] if passed anything other than a TargetValue
    # @param other [TargetValue] the json value being checked
    # @return [Bool]
    # @api public
    # @example
    #   object = Struct.new(:id).new(1)
    #   expected = ExpectedValue.new(:default, object, 'id', 'class_name')
    #   target = TargetValue.new('class_name.id', { 'class_name' => { 'id' => 1 }})
    #   expected_value == target_value
    #   #=> true
    def ==(other)
      raise ArgumentError unless other.is_a? TargetValue
      other.value == value
    end

    private

    # @api private
    # @param instance [Object]
    # @param function [Symbol,Proc] :default uses the key to determine the method calls
    #                               otherwise a custom Proc can be passed
    # @param key [String] the part of the json key pertaining to this instance
    # @param prefix [String] the part of the key before this instance
    # @return [String,Integer]
    def fetch_expected_value(instance, function, key, prefix)
      if function == :default
        key.split('.').inject(instance) do |expected, method_name|
          method_name = method_name.chomp('_attributes')
          method_name == prefix ? expected : expected&.send(method_name)
        rescue NoMethodError
          nil
        end
      else
        function.call(instance)
      end
    end
  end
end
