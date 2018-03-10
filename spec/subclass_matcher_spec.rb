require_relative '../lib/json_rspec_match_maker'

Struct.new('Associated', :id, :description)
test_associated = Struct::Associated.new(2, 'An associated record')

Struct.new('Instance', :id, :name, :association)
test_instance = Struct::Instance.new(1, 'test', [test_associated])

class ExampleMatcher < JsonRspecMatchMaker::Base
  MATCH_DEF = {
    'id' => {
      instance: ->(instance) { instance.id },
      json: ->(json) { json['id'] }
    },
    'name' => {
      instance: ->(instance) { instance.name },
      json: ->(json) { json['name'] }
    },
    'association' => {
      association: ->(instance) { instance.association },
      attributes: {
        'id' => {
          instance: ->(instance) { instance.id },
          json: ->(json, idx) { json['association'][idx]['id'] }
        },
        'description' => {
          instance: ->(instance) { instance.description },
          json: ->(json, idx) { json['association'][idx]['description'] }
        }
      }
    }
  }.freeze

  def initialize(instance)
    @match_definition = MATCH_DEF.dup
    super
  end
end

matching_json = {
  'id' => test_instance.id,
  'name' => test_instance.name,
  'association' => [
    {
      'id' => test_associated.id,
      'description' => test_associated.description
    }
  ]
}

mismatching_json = {
  'id' => test_instance.id,
  'name' => 'Not Name',
  'association' => [
    {
      'id' => test_associated.id,
      'description' => test_associated.description
    }
  ]
}

RSpec.describe 'Subclass Matcher' do
  let(:matcher) { ExampleMatcher.new(test_instance) }

  describe 'matches?' do
    it 'returns true for matching json' do
      expect(matcher.matches?(matching_json)).to eq true
    end

    it 'returns false for mismatching json' do
      expect(matcher.matches?(mismatching_json)).to eq false

      expect(matcher.failure_message).to(
        eq 'Mismatch in field name: expected (test), got: (Not Name)'
      )
    end
  end
end
