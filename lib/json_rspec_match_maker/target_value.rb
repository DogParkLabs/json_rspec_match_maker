module JsonRspecMatchMaker
  # Handles fetching the target value from the target object
  class TargetValue
    attr_reader :error_key, :value

    def initialize(key, each_opts, target)
      @error_key = full_error_key(key, each_opts)
      @value = fetch_value(key, each_opts, target)
    end

    def full_error_key(key, each_opts)
      return key if each_opts.nil?

      "#{key}[#{each_opts[:idx]}].#{each_opts[:error_key]}"
    end

    def fetch_value(key, each_opts, target)
      return value_for_key(key, target) if each_opts.nil?

      targets = value_for_key(key, target)
      specific_target = targets[each_opts[:idx]]
      value_for_key(each_opts[:error_key], specific_target)
    end

    def value_for_key(key, json)
      value = key.split('.').reduce(json) { |j, k| j.fetch(k, {}) }
      value == {} ? nil : value
    end

    def ==(other)
      raise ArgumentError unless other.is_a? ExpectedValue
      other.value == value
    end
  end
end
