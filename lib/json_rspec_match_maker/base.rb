module JsonMatchers
  # Error raised when the child class has failed to set @match_definition
  class MatchDefinitionNotFound < StandardError
    def initialize(class_name)
      super("Expected instance variable @match_defintion to be set for #{class_name}")
    end
  end

  # Base class that abstracts away all of the work of using the @match_definition
  class Base
    attr_reader :instance, :json, :match_definition

    def initialize(instance)
      @instance = instance
      @errors = {}
    end

    def matches?(json)
      @json = json
      check_json_against_instance
      @errors.empty?
    end

    def failure_message
      @errors.values.join('\n')
    end

    private

    def check_json_against_instance
      raise MatchDefinitionNotFound, self.class.name unless @match_definition
      @match_definition.each do |error_key, match_def|
        if match_def[:association].present?
          check_association(error_key, match_def)
        else
          check_values(error_key, match_def)
        end
      end
    end

    def check_association(error_key, association_definition)
      association_definition[:attributes].each do |attr_error_key, match_functions|
        association_definition[:association].call(instance).each_with_index do |associated_instance, idx|
          full_error_key = "#{error_key}[#{idx}].#{attr_error_key}"
          check_values(full_error_key, match_functions, associated_instance, idx)
        end
      end
    end

    def check_values(error_key, match_functions, expected_instance = instance, idx = nil)
      instance_value = match_functions[:instance].call(expected_instance)
      json_value = if idx.nil?
                     match_functions[:json].call(json)
                   else
                     match_functions[:json].call(json, idx)
                   end
      add_error(error_key, instance_value, json_value) if instance_value != json_value
    end

    def add_error(field, instance_value, json_value)
      @errors[field] = "Mismatch in field #{field}: expected (#{instance_value}), got: #{json_value}"
    end
  end
end
