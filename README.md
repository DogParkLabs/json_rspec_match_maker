# JsonRspecMatchMaker

Write RSpec matchers for JSON api endpoints using a simple data structure.
DRY up API expectations, without losing the specificity sacrificed by a
schema-based approach to JSON expectations.

## Why?

As pointed out by Thoughbot in their blog post [Validating JSON Schemas with an
RSpec
Matcher](https://robots.thoughtbot.com/validating-json-schemas-with-an-rspec-matcher)
the naive pattern for writing request specs for a JSON API in rails tends to
look something like:

```ruby
describe "Fetching the current user" do
  context "with valid auth token" do
    it "returns the current user" do
      user = create(:user)
      auth_header = { "Auth-Token" => user.auth_token }

      get v1_current_user_url, {}, auth_header

      current_user = response_body["user"]
      expect(response.status).to eq 200
      expect(current_user["auth_token"]).to eq user.auth_token
      expect(current_user["email"]).to eq user.email
      expect(current_user["first_name"]).to eq user.first_name
      expect(current_user["last_name"]).to eq user.last_name
      expect(current_user["id"]).to eq user.id
      expect(current_user["phone_number"]).to eq user.phone_number
    end
  end

  def response_body
    JSON.parse(response.body)
  end
end
```

Tedious to write and just as tedious to read.

In that post, they talk about one alternative for making tests around JSON
better - JSON Schema. This is an interesting approach, but I'd like to be more
specific about my specs than validating that the shape of the data and the types
of the values are correct.

However, I do like the way that the JSON schema is written because it is very
similar to the JSON that's generated. So that's the goal - enable writing spec
matchers similar to a JSON schema definition but with greater specificity about values.

I think this gem accomplishes that. As an example, here is a JSON Schema
defintion (also pulled from the Thoughbot blog post)

```json
{
  "type": "object",
  "required": ["user"],
  "properties": {
    "user" : {
      "type" : "object",
      "required" : [
        "auth_token",
        "email",
        "first_name",
        "id",
        "last_name",
        "phone_number"
      ],
      "properties" : {
        "auth_token" : { "type" : "string" },
        "created_at" : { "type" : "string", "format": "date-time" },
        "email" : { "type" : "string" },
        "first_name" : { "type" : "string" },
        "id" : { "type" : "integer" },
        "last_name" : { "type" : "string" },
        "phone_number" : { "type" : "string" },
        "updated_at" : { "type" : "string", "format": "date-time" }
      }
    }
  }
}
```

And here is what the interesting bits of a matcher using this gem would look
like for the same case:

```ruby
{
  'user.auth_token' =>   ->(user) { user.auth_token },
  'user.created_at' =>   ->(user) { user.created_at },
  'user.email' =>        ->(user) { user.email },
  'user.first_name' =>   ->(user) { user.first_name },
  'user.id' =>           ->(user) { user.id },
  'user.last_name' =>    ->(user) { user.last_name }
  'user.phone_number' => ->(user) { user.phone_number },
  'user.updated_at' =>   ->(user) { user.updated_at }
}
```

Then that matcher can be used to make your specs:

```ruby
describe "Fetching the current user" do
  context "with valid auth token" do
    it "returns the current user" do
      user = create(:user)
      auth_header = { "Auth-Token" => user.auth_token }

      get v1_current_user_url, {}, auth_header

      expect(response_body).to be_valid_json_for_user(user)
    end
  end

  def response_body
    JSON.parse(response.body)
  end
end
```

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

Arrays are defined very similary to single objects:

```ruby
{
  'answers' => {
    each: ->(instance) { instance.answers },
    attributes: {
      'id' => ->(answer) { answer.id },
      'question' => ->(answer) { answer.question.text },
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
