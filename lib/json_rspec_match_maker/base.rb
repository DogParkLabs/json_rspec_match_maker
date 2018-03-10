module JsonRspecMatchMaker
  # Error raised when the child class has failed to set @match_definition
  # @api private
  class MatchDefinitionNotFound < StandardError
    # Create an error message for a child class
    # @param class_name [String] the name of the matcher class
    def initialize(class_name)
      super("Expected instance variable @match_defintion to be set for #{class_name}")
    end
  end

  # Base class that abstracts away all of the work of using the @match_definition
  class Base
    # The object being expected against
    # @api private
    # @return [Object]
    attr_reader :expected

    # The json being tested
    # @api private
    # @return [Hash]
    attr_reader :target

    # Data structure that specifies how instance values relate to JSON values
    # @api private
    # @return [Hash]
    attr_reader :match_definition

    # Create a new JSON matcher
    # @api public
    # @param expected [Object] The object being serialized into JSON
    # @example
    #   JsonRspecMatchMaker.new(active_record_model)
    #   JsonRspecMatchMaker.new(presenter_instance)
    def initialize(expected)
      @expected = expected
      @errors = {}
    end

    # Match method called by RSpec
    # @api public
    # @return [Bool]
    # @example
    #   JsonRspecMatchMaker.new(user).matches?(user.to_json) #=> true
    #   JsonRspecMatchMaker.new(dog).matches?(cat.to_json) #=> false
    def matches?(target)
      @target = target
      check_target_against_expected
      @errors.empty?
    end

    # Error reporting method called by RSpec
    # @api public
    # @return [String]
    # @example
    #   match_maker.failure_message #=> 'Mismatch in field name: expected (Freddy) got (Harold)'
    def failure_message
      @errors.values.join('\n')
    end

    private

    # Walks through the match definition, collecting errors for each field
    # @api private
    # @raise [MatchDefinitionNotFound] if child class does not set @match_definition
    # @return [nil] returns nothing, adds to error list as side effect
    def check_target_against_expected
      raise MatchDefinitionNotFound, self.class.name unless @match_definition
      @match_definition.each do |error_key, match_def|
        if match_def.respond_to? :call
          check_values(error_key, match_def)
        else
          check_each(error_key, match_def)
        end
      end
    end

    # Iterates through a list of objects while checking fields
    # @api private
    # @param error_key [String]
    #   the first name of the field reported in the error
    #   each errors are reported #{error_key}[#{idx}].#{each_key}
    # @param each_definition [Hash]
    #   :each is a function that returns the list of items
    #   :attributes is a hash with the same structure as the top-level match_def hash
    # @return [nil] returns nothing, adds to error list as side effect
    def check_each(error_key, each_definition)
      enumerable = each_definition[:each].call(expected)
      enumerable.each_with_index do |each_instance, idx|
        each_definition[:attributes].each do |attr_error_key, match_function|
          each_opts = { idx: idx, error_key: attr_error_key }
          check_values(error_key, match_function, each_instance, each_opts)
        end
      end
    end

    # Checks fields on a single instance
    # @api private
    # @param error_key [String] the name of the field reported in the error
    # @param match_function [Hash]
    #   a function returning the value for the key for the object being serialized
    # @param expected_instance [Object]
    #   the top level instance, or an each instance from #check_each
    # @param each_opts [nil, Hash]
    #  nil if checking a top level value
    #  Hash if iterating through a list
    #    :idx the current index
    #    :error_key the subfield reported in the error
    # the index if iterating through a list, otherwise nil
    # @return [nil] returns nothing, adds to error list as side effect
    def check_values(error_key, match_function, expected_instance = expected, each_opts = nil)
      expected_value = match_function.call(expected_instance)
      if each_opts.nil?
        target_value = value_for_key(error_key, target)
      else
        targets = value_for_key(error_key, target)
        specific_target = targets[each_opts[:idx]]
        target_value = value_for_key(each_opts[:error_key], specific_target)
        error_key = "#{error_key}[#{each_opts[:idx]}].#{each_opts[:error_key]}"
      end
      add_error(error_key, expected_value, target_value) if expected_value != target_value
    end

    def value_for_key(key, json)
      key.split('.').reduce(json) { |j, k| j[k] }
    end

    # Adds an erorr to the list when a mismatch is detected
    # @api private
    # @return [String] the error message
    def add_error(field, expected_value, target_value)
      @errors[field] =
        "Mismatch in field #{field}: expected (#{expected_value}), got: (#{target_value})"
    end
  end
end
