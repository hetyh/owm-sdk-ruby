# OwmSdk

Example SDK for working with OpenWeatherMap

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add owm_sdk

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install owm_sdk

## Usage

SDK supports two working mode: on demand and polling.

On demand usage:

```ruby

require 'owm_sdk'

client = OwmSdk::Weather.new(
    api_key: "OpenWeatherMap API Key",
    mode: "on_demand",
    units: "metric"
)

puts client.get_weather("London")

# Requested data is now cached for next 10 minutes

```

Polling usage:

```ruby

require 'owm_sdk'

client = OwmSdk::Weather.new(
    api_key: "...",
    mode: "polling",
    units: "metric",
)

puts client.get_weather("London")

# Weather data for requested location 
# will be constantly updated in the background

puts client.get_weather("London") # Gets new data with zero latency
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hetyh/owm-sdk-ruby.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
