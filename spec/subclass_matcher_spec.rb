require 'spec_helper'

Struct.new('SingleAssociated', :id, :type)
test_single_associated = Struct::SingleAssociated.new(3, :foo)

Struct.new('ManyAssociated', :id, :description, :something_else)
test_many_associated = Struct::ManyAssociated.new(
  2, 'An associated record in a list', test_single_associated
)

class TestInstance
  attr_reader :id, :first_name, :last_name, :many_association, :single_association

  def initialize(id, first_name, last_name, many_association, single_association)
    @id = id
    @first_name = first_name
    @last_name = last_name
    @many_association = [many_association]
    @single_association = single_association
  end

  def full_name
    [first_name, last_name].join(' ')
  end
end
test_instance =
  TestInstance.new(1, 'John', 'Johnson', test_many_associated, test_single_associated)

class ExampleMatcher < JsonRspecMatchMaker::Base
  MATCH_DEF = {
    'id' => ->(instance) { instance.id },
    'name' => ->(instance) { instance.full_name },
    'single_association.id' => ->(instance) { instance.single_association.id },
    'single_association.type' => ->(instance) { instance.single_association.type },
    'many_association' => {
      each: ->(instance) { instance.many_association },
      attributes: {
        'id' => ->(each_instance) { each_instance.id },
        'description' => ->(each_instance) { each_instance.description },
        'something_else.id' => ->(each_instance) { each_instance.something_else.id },
        'something_else.type' => ->(each_instance) { each_instance.something_else.type }
      }
    }
  }.freeze

  def initialize(instance)
    @match_definition = MATCH_DEF.dup
    super
  end
end

# rubocop:disable Metrics/BlockLength
RSpec.describe 'Subclass Matcher' do
  let(:matcher) { ExampleMatcher.new(test_instance) }

  let(:matching_json) do
    {
      'id' => test_instance.id,
      'name' => test_instance.full_name,
      'single_association' => {
        'id' => test_single_associated.id,
        'type' => test_single_associated.type
      },
      'many_association' => [
        {
          'id' => test_many_associated.id,
          'description' => test_many_associated.description,
          'something_else' => {
            'id' => test_single_associated.id,
            'type' => test_single_associated.type
          }
        }
      ]
    }
  end

  let(:mismatching_json_single) do
    matching_json.dup.tap do |json|
      json['name'] = 'John Johnson '
    end
  end

  let(:mismatching_json_many) do
    matching_json.dup.tap do |json|
      json['many_association'][0]['description'] = 'Nonsense'
    end
  end

  describe 'matches?' do
    it 'returns true for matching json' do
      expect(matcher.matches?(matching_json)).to eq true
    end

    it 'returns false for mismatching json' do
      expect(matcher.matches?(mismatching_json_single)).to eq false

      expect(matcher.failure_message).to(
        eq 'Mismatch in field name: expected (John Johnson), got: (John Johnson )'
      )
    end

    it 'returns error messages for each errors' do
      expect(matcher.matches?(mismatching_json_many)).to eq false

      field_name = 'many_association[0].description'
      description = 'An associated record in a list'
      expect(matcher.failure_message).to(
        eq "Mismatch in field #{field_name}: expected (#{description}), got: (Nonsense)"
      )
    end
  end
end
# rubocop:enable Metrics/BlockLength
