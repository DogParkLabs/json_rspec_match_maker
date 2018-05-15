# frozen_string_literal: true

module JsonRspecMatchMaker
  # Handles fetching the expected value from the expected instance
  class ExpectedValue
    attr_reader :value
    def initialize(match_function, expected_instance, error_key)
      @value = fetch_expected_value(expected_instance, match_function, error_key)
    end

    def ==(other)
      raise ArgumentError unless other.is_a? TargetValue
      other.value == value
    end

    private

    def fetch_expected_value(instance, function, key)
      if function == :default
        key.split('.').inject(instance) do |expected, k|
          expected&.send k
        rescue NoMethodError
          nil
        end
      else
        function.call(instance)
      end
    end
  end
end
