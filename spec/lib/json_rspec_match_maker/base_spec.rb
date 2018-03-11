RSpec.describe JsonRspecMatchMaker::Base do
  Struct.new('Example', :id, :name, :description)

  let(:expected) { Struct::Example.new(1, 'test', 'a test object') }
  let(:matcher) { JsonRspecMatchMaker::Base.new(expected) }
  let(:target) { { id: 1, name: 'test', description: 'a test object' } }

  describe '#initialize' do
    it 'is initialized with the instance being expected against' do
      expect(matcher.expected).to eq expected
    end
  end

  describe '#matches?' do
    it 'raises an error if no @match_definition is set' do
      expect { matcher.matches?(target) }.to raise_error JsonRspecMatchMaker::MatchDefinitionNotFound
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
