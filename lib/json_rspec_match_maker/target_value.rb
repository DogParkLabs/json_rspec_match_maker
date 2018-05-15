# frozen_string_literal: true

module JsonRspecMatchMaker
  # Handles fetching the target value from the target object
  class TargetValue
    attr_reader :error_key, :value

    NUMBER = /^\d+$/

    def initialize(key, target)
      @error_key = key
      @value = value_for_key(key, target)
    end

    def ==(other)
      raise ArgumentError unless other.is_a? ExpectedValue
      other.value == value
    end

    private

    def value_for_key(key, json)
      value = key.split('.').reduce(json) do |j, k|
        k.match?(NUMBER) ? (j[k.to_i] || {}) : j.fetch(k, {})
      end
      value == {} ? nil : value
    end
  end
end
