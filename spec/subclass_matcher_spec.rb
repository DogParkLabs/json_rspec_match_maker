# frozen_string_literal: true

Struct.new('SingleAssociated', :id, :type)
test_single_associated = Struct::SingleAssociated.new(3, :foo)

Struct.new('ManyAssociated', :id, :description, :something_else, :more_things)
test_many_associated = Struct::ManyAssociated.new(
  2, 'An associated record in a list', test_single_associated, [test_single_associated]
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

# rubocop:disable Metrics/BlockLength
class ExampleMatcher < JsonRspecMatchMaker::Base
  COMPLEX_MATCH_DEF = {
    'testy.id' => ->(instance) { instance.id },
    'name' => ->(instance) { instance.full_name },
    'non.existant.nested.key.value' => ->(_) { nil },
    'single_association_attributes.id' => :default,
    'single_association_attributes.type' => ->(instance) { instance.single_association.type },
    'many_association' => {
      each: ->(instance) { instance.many_association },
      attributes: {
        'id' => ->(each_instance) { each_instance.id },
        'description' => ->(each_instance) { each_instance.description },
        'something_else.id' => ->(each_instance) { each_instance.something_else.id },
        'something_else.type' => ->(each_instance) { each_instance.something_else.type },
        'more_things' => {
          each: ->(each_instance) { each_instance.more_things },
          attributes: {
            'id' => ->(thing) { thing. id },
            'type' => ->(thing) { thing.type }
          }
        }
      }
    }
  }.freeze

  SIMPLE_MATCH_DEF = [
    'testy.id',
    'non.existant.key.value',
    'single_association_attributes.id',
    'single_association_attributes.type',
    'name' => ->(instance) { instance.full_name },
    'many_association' => {
      each: ->(instance) { instance.many_association },
      attributes: [
        'id',
        'description',
        'something_else.id',
        'something_else.type',
        'more_things' => {
          each: ->(instance) { instance.more_things },
          attributes: %w[id type]
        }
      ]
    }
  ].freeze
end

RSpec.shared_examples 'json matcher' do |type|
  if type == :simple
    let(:matcher) do
      ExampleMatcher.new(test_instance, ExampleMatcher::SIMPLE_MATCH_DEF, prefix: 'testy')
    end
  else
    let(:matcher) do
      ExampleMatcher.new(test_instance, ExampleMatcher::COMPLEX_MATCH_DEF, prefix: 'testy')
    end
  end

  let(:matching_json) do
    {
      'testy' => { 'id' => test_instance.id },
      'name' => test_instance.full_name,
      'single_association_attributes' => {
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
          },
          'more_things' => [
            {
              'id' => test_single_associated.id,
              'type' => test_single_associated.type
            }
          ]
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

  let(:mismatching_json_many_nested) do
    matching_json.dup.tap do |json|
      json['many_association'][0]['more_things'][0]['type'] = 'Nonsense'
    end
  end

  describe 'matches?' do
    it 'returns true for matching json' do
      expect(matcher.matches?(matching_json)).to eq true
    end

    it 'returns false for mismatching json' do
      expect(matcher.matches?(mismatching_json_single)).to eq false

      # rubocop:disable Layout/EmptyLinesAroundArguments
      expect(matcher.failure_message).to(
        eq <<-MSG

        Mismatch in field: 'name'
          expected: 'John Johnson'
          received: 'John Johnson '

        MSG
      )
    end

    it 'returns error messages for each errors' do
      expect(matcher.matches?(mismatching_json_many)).to eq false

      field_name = 'many_association.0.description'
      description = 'An associated record in a list'
      expect(matcher.failure_message).to(
        eq <<-MSG

        Mismatch in field: '#{field_name}'
          expected: '#{description}'
          received: 'Nonsense'

        MSG
      )
    end

    it 'returns error messages for deeply nested each errors' do
      expect(matcher.matches?(mismatching_json_many_nested)).to eq false

      field_name = 'many_association.0.more_things.0.type'
      type = 'foo'
      expect(matcher.failure_message).to(
        eq <<-MSG

        Mismatch in field: '#{field_name}'
          expected: '#{type}'
          received: 'Nonsense'

        MSG
      )
    end
    # rubocop:enable Layout/EmptyLinesAroundArguments
  end
end
# rubocop:enable Metrics/BlockLength

RSpec.describe 'Subclass Matcher' do
  context 'complex' do
    describe 'complex match definition' do
      it_behaves_like 'json matcher', :complex
    end
  end

  describe 'simple match definition' do
    it_behaves_like 'json matcher', :simple
  end
end
