# JsonRspecMatchMaker

Helper class for writing custom RSpec matchers for JSON api endpoints.

DRY up API expectations, without losing the specificity sacrificed by a
schema-based approach.

## Installation with Rails

Add this line to your application's Gemfile:

```
gem 'json_rspec_match_maker', require: false
```

And then execute:

    $ bundle
    
Update your `rails_helper.rb` with:

```
# require the gem
require 'json_rspec_match_maker'

# require your custom matchers you'll be writing
Dir[Rails.root.join('spec/support/matchers/json_matchers/**/*.rb')].each do |f|
  require f
end
```

## Usage

Matchers are instantiated with some object and a match definition.

If our address class looks like:

```
class Address
  attr_reader :street1, :street2, :city, :state, :zip
end
```

And we serialize that into JSON like:

```
{
  address: {
    street1: '18 Streety Street',
    street2: 'APT 22B',
    city: 'Citytown',
    state: 'NY',
    zip: '11111'
  }
}
```

Then we can define a matcher like:

```
module JsonMatchers
  def be_valid_json_for_address(address)
    JsonRspecMatchMaker::Base.new(address, %w[street1 street2 city state zip], prefix: 'address')
  end
end
```

And use it in a spec like:

```
describe 'my api', type: :request do
  let(:test_address) { Address.new('Street', '2', 'Place', 'ZZ', '00000') }
  it 'gets some stuff' do
    get '/api/address'
    expect(JSON.parse(response.body)).to be_valid_json_for_address(test_address)
  end
end
```

You can also pass a custom Proc to override the methods called to fetch the value for a key:
(these need to be last in the array - taking advantage of ruby sytanx sugar omitting surrounding brackets)

```
match = [
  'id',
  'name' => ->(object) { object.full_name }
]
```

Single nested objects are simple:

```
match = [
  'user.address.street1'
]
```

Nested lists have one extra step
:each should be a proc that fetches the list to iterate through
:attributes should be another definition, following same rules as the outer one

```
match = [
  'id',
  'name',
  'photographs_attributes' => {
    each: -> (object) { object.photographs.visible },
    attributes: %w[id caption url]
  }
]
```

You may want to break out more complicated definitions into their own class:

```
module JsonMatchers
  class AddressMatcher < JsonRspecMatchMaker::Base
    MATCH = %w[street1 street2 city state zip].freeze
    
    def initialize(address)
      super(address, MATCH, prefix: 'address')
    end
  end

  def be_valid_json_for_address(address)
    AddressMatcher.new(address)
  end
end
```

You might want your matchers to be more dynamic so you could do something like:

```ruby
class AddressMatcher < JsonRspecMatchMaker::Base
  def initialize(address, state_format)
    match_definition = set_match_def(state_format)
    super(address, match_definition)
  end
  
  def set_match_def(state_format)
    [
      'state' => ->(instance) { instance.state.formatted(state_format) }
    ]
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/json_rspec_match_maker. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the JsonRspecMatchMaker project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/json_rspec_match_maker/blob/master/CODE_OF_CONDUCT.md).
