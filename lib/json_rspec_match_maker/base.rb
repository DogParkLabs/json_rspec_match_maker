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
    attr_reader :instance

    # The json being tested
    # @api private
    # @return [Hash]
    attr_reader :json

    # Data structure that specifies how instance values relate to JSON values
    # @api private
    # @return [Hash]
    attr_reader :match_definition

    # Create a new JSON matcher
    # @api public
    # @param instance [Object] The object being serialized into JSON
    # @example
    #   JsonRspecMatchMaker.new(active_record_model)
    #   JsonRspecMatchMaker.new(presenter_instance)
    def initialize(instance)
      @instance = instance
      @errors = {}
    end

    # Match method called by RSpec
    # @api public
    # @return [Bool]
    # @example
    #   JsonRspecMatchMaker.new(user).matches?(user.to_json) #=> true
    #   JsonRspecMatchMaker.new(dog).matches?(cat.to_json) #=> false
    def matches?(json)
      @json = json
      check_json_against_instance
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
    def check_json_against_instance
      raise MatchDefinitionNotFound, self.class.name unless @match_definition
      @match_definition.each do |error_key, match_def|
        if match_def[:each_with_index].nil?
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
    #   :each_with_index is a function that returns the list of items
    #   :attributes is a hash with the same structure as the top-level match_def hash
    # @return [nil] returns nothing, adds to error list as side effect
    def check_each(error_key, each_definition)
      enumerable = each_definition[:each_with_index].call(instance)
      enumerable.each_with_index do |each_instance, idx|
        each_definition[:attributes].each do |attr_error_key, match_functions|
          full_error_key = "#{error_key}[#{idx}].#{attr_error_key}"
          check_values(full_error_key, match_functions, each_instance, idx)
        end
      end
    end

    # Checks fields on a single instance
    # @api private
    # @param error_key [String] the name of the field reported in the error
    # @param match_functions [Hash]
    #  :instance is a function returning the value for the key for the object being serialized
    #  :json is a function returning the value for the key for the json
    # @param expected_instance [Object]
    #   the top level instance, or an each instance from #check_each
    # @param idx [nil, Integer] the index if iterating through a list, otherwise nil
    # @return [nil] returns nothing, adds to error list as side effect
    def check_values(error_key, match_functions, expected_instance = instance, idx = nil)
      instance_value = match_functions[:instance].call(expected_instance)
      json_value = if idx.nil?
                     match_functions[:json].call(json)
                   else
                     match_functions[:json].call(json, idx)
                   end
      add_error(error_key, instance_value, json_value) if instance_value != json_value
    end

    # Adds an erorr to the list when a mismatch is detected
    # @api private
    # @return [String] the error message
    def add_error(field, instance_value, json_value)
      @errors[field] =
        "Mismatch in field #{field}: expected (#{instance_value}), got: (#{json_value})"
    end
  end
end
