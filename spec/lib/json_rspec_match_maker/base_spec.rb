require 'spec_helper'

RSpec.describe JsonRspecMatchMaker::Base do
  Struct.new('Example', :id, :name, :description)

  let(:instance) { Struct::Example.new(1, 'test', 'a test object') }
  let(:matcher) { JsonRspecMatchMaker::Base.new(instance) }
  let(:json) { { id: 1, name: 'test', description: 'a test object' } }

  describe '#initialize' do
    it 'is initialized with the instance being expected against' do
      expect(matcher.instance).to eq instance
    end
  end

  describe '#matches?' do
    it 'raises an error if no @match_definition is set' do
      expect { matcher.matches?(json) }.to raise_error JsonRspecMatchMaker::MatchDefinitionNotFound
    end
  end

  describe '#failure_message' do
    let(:error_message) { 'Mismatch detected in field name: expected (test), got: (best)' }

    it 'returns a list of all errors encountered while matching' do
      matcher.send(:instance_variable_set, :@errors, name: error_message)
      expect(matcher.failure_message).to eq error_message
    end
  end
end
