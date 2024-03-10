# frozen_string_literal: true

require_relative 'owm_sdk/version'

require 'octopoller'
require 'lru_redux'

require 'uri'
require 'net/http'
require 'json'

module OwmSdk
  class Error < StandardError; end

  class Weather
    def get_weather(city)
      weather = @weather_cache[city] unless @mode == :polling

      return weather unless weather.nil?

      location = get_location(city)

      weather = get_weather_request(location)

      unless weather.nil?
        @weather_cache[city] = weather
        return weather
      end

      Kernel.raise Error, 'Weather data for provided city was not found'
    end

    def initialize(api_key, mode = :on_demand, units = :standard)
      @api_key = api_key
      @units = units
      @location_cache = LruRedux::Cache.new(10)
      @weather_cache = LruRedux::TTL::Cache.new(10, 600)

      @polling_rate = 600
      @mode = mode
      @polling_thread = Thread.new { polling_loop } if @mode == :polling
    end

    private

    def get(path, query)
      uri = URI.parse('https://api.openweathermap.org')
      uri.path = path
      uri.query = URI.encode_www_form(query)

      res = Net::HTTP.get_response(uri)
      body = JSON.parse(res.body)
      raise Error, "Got HTTP response #{res.code}, message: '#{body['message']}'" unless res.code == '200'

      body
    end

    def get_weather_request(location)
      get('/data/2.5/weather', { lat: location[:lat], lon: location[:lon], appid: @api_key, units: @units.to_s })
    end

    def get_location_request(city)
      res = get('/geo/1.0/direct', { q: city, limit: 1, appid: @api_key })

      raise Error, 'Provided city was not found' if res[0].nil?

      lat = res[0]['lat']
      lon = res[0]['lon']

      { lat: lat, lon: lon }
    end

    def get_location(city)
      location = @location_cache[city]

      return location unless location.nil?

      location = get_location_request(city)

      unless location.nil?
        @location_cache[city] = location
        return location
      end

      Kernel.raise Error, 'oops'
    end

    def update_weather
      @location_cache.to_a.each do |city|
        get_weather(city[0])
      end
    end

    def polling_loop
      loop do
        begin
          update_weather
        rescue Error => e
          puts "Error during API requests: #{e.message}"
        end

        sleep @polling_rate
      end
    end
  end
end

test = OwmSdk::Weather.new('c39024401ccb1736e173fda2bf622417', :on_demand, :metric)

puts test.get_weather(2)
