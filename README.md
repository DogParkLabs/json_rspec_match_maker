# JsonRspecMatchMaker

Write RSpec matchers for JSON api endpoints using a simple data structure.
DRY up API expectations, without losing the specificity sacrificed by a
schema-based approach to JSON expectations.

## Why?



## Installation with Rails

Add this line to your application's Gemfile:

```ruby
gem 'json_rspec_match_maker', require: false
```

And then execute:

    $ bundle
    
Update your `rails_helper.rb` with:

```ruby
# require the gem
require 'json_rspec_match_maker'

# require your custom matchers you'll be writing
Dir[Rails.root.join('spec/support/matchers/json_matchers/**/*.rb')].each do |f|
  require f
end
```

## Usage

Create a new matcher that interhits from the base class:

```ruby
class AddressMatcher < JsonRspecMatchMaker::Base
end
```

A child class just needs to define and set the `@match_definition` 

```ruby
class AddressMatcher < JsonRspecMatchMaker::Base
  def initialize(address)
    @match_definition = set_match_def
    super
  end
end
```

Matchers need to be wrapped in a module we can include in our specs:

```ruby
module JsonMatchers
  class AddressMatcher < JsonRspecMatchMaker::Base
    ...
  end
end
```

That module defines our match method:

```ruby
module JsonMatchers
  # class defined up here...
  
  def be_valid_json_for_address(address)
    AddressMatcher.new(address)
  end
end
```

Which we can then use in RSpec like:

```ruby
RSpec.describe 'Address serialization' do
  include JsonMatchers

  let(:address) { Address.new }
  let(:address_json) { address.to_json }
  
  it 'serializes the address' do
    expect(address_json).to be_valid_json_for_address(address)
  end
end
```

Here is an example of a complete matcher class:

```ruby
class AddressMatcher < JsonRspecMatchMaker::Base
  MATCH_DEF = {
    'id' => ->(instance) { instance.id },
    'description' => ->(instance) { instance.description },
    'street_line_one' => ->(instance) { instance.street_line_one },
    'street_line_two' => ->(instance) { instance.street_line_two },
    'city' => ->(instance) { instance.city },
    'state' => ->(instance) { instance.state.abbreviation },
    'postal_code' => ->(instance) { instance.postal_code },
  }.freeze

  def initialize(address)
    @match_definition = MATCH_DEF
    super
  end
end
```

In that cause, our expectations are static so we can define the match definition
as a constant.

In other cases, we might want our matchers to be more dynamic so we could do
something like:

```ruby
class AddressMatcher < JsonRspecMatchMaker::Base
  def initialize(address, state_format)
    @match_definition = set_match_def(state_format)
    super(address)
  end
  
  def set_match_def(state_format)
    {
      'state' => ->(instance) { instance.state.formatted(state_format) }
    }.merge(MATCH_DEF)
  end
end
```

Associations are defined very similarly to top level attributes:

```ruby
{
  'answers' => {
    association: ->(instance) { instance.answers },
    attributes: {
      'id' => ->(instance) { instance.id },
      'question' => ->(instance) { instance.question.text },
    }
  }
}
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
