module JsonRspecMatchMaker
  # Handles fetching the expected value from the expected instance
  class ExpectedValue
    attr_reader :value
    def initialize(match_function, expected_instance)
      @value = match_function.call(expected_instance)
    end

    def ==(other)
      raise ArgumentError unless other.is_a? TargetValue
      other.value == value
    end
  end
end
