# frozen_string_literal: true

module JsonRspecMatchMaker
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
    def initialize(expected, match_definition, prefix: '')
      @expected = expected
      @match_definition = expand_definition(match_definition)
      @errors = {}
      @prefix = prefix
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

    # expands simple arrays into full hash definitions
    # @api private
    def expand_definition(definition)
      return definition if definition.is_a? Hash
      definition.each_with_object({}) do |key, result|
        if key.is_a? String
          result[key] = :default
        elsif key.is_a? Hash
          result.merge!(expand_sub_definitions(key))
        end
      end
    end

    # expands nested simple definition into a full hash
    # @api private
    def expand_sub_definitions(sub_definitions)
      sub_definitions.each_with_object({}) do |(subkey, value), result|
        result[subkey] = value
        next if value.respond_to? :call
        result[subkey][:attributes] = expand_definition(value[:attributes])
      end
    end

    # Walks through the match definition, collecting errors for each field
    # @api private
    # @raise [MatchDefinitionNotFound] if child class does not set @match_definition
    # @return [nil] returns nothing, adds to error list as side effect
    def check_target_against_expected
      check_definition(@match_definition, expected)
    end

    def check_definition(definition, current_expected, current_key = nil)
      definition.each do |error_key, match_def|
        if match_def.is_a? Hash
          key = [current_key, error_key].compact.join('.')
          check_each(key, match_def, current_expected)
        else
          check_values(current_key, error_key, match_def, current_expected)
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
    def check_each(error_key, each_definition, current_expected)
      enumerable = each_definition[:each].call(current_expected)
      enumerable.each_with_index do |each_instance, idx|
        full_key = [error_key, idx].join('.')
        check_definition(each_definition[:attributes], each_instance, full_key)
      end
    end

    # Checks fields on a single instance
    # @api private
    # @param error_key [String] the name of the field reported in the error
    # @param match_function [Hash]
    #   a function returning the value for the key for the object being serialized
    # @param expected_instance [Object]
    #   the top level instance, or an each instance from #check_each
    # the index if iterating through a list, otherwise nil
    # @return [nil] returns nothing, adds to error list as side effect
    def check_values(key_prefix, error_key, match_function, expected_instance = expected)
      expected_value = ExpectedValue.new(match_function, expected_instance, error_key, @prefix)
      target_value = TargetValue.new([key_prefix, error_key].compact.join('.'), target)
      add_error(expected_value, target_value) unless expected_value == target_value
    end

    # Adds an erorr to the list when a mismatch is detected
    # @api private
    # @return [String] the error message
    def add_error(expected_value, target_value)
      @errors[target_value.error_key] = <<-MSG

        Mismatch in field: '#{target_value.error_key}'
          expected: '#{expected_value.value}'
          received: '#{target_value.value}'

      MSG
    end
  end
end
