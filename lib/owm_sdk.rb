# frozen_string_literal: true

require_relative "owm_sdk/version"

require "lru_redux"

require "uri"
require "net/http"
require "json"

module OwmSdk
  class Error < StandardError; end

  class RequestError < StandardError; end

  class ServerError < StandardError; end

  class Weather
    POLLING_RATE = 600
    LOCATION_CACHE_SIZE = 10
    WEATHER_CACHE_SIZE = 10
    WEATHER_CACHE_TTL = 600

    def get_weather(city)
      location = get_location(city)

      weather_cached = @weather_cache[location]
      return weather_cached unless weather_cached.nil?

      get_weather_request(location)
    end

    def initialize(api_key, mode = :on_demand, units = :standard)
      @api_key = api_key
      @units = units
      @location_cache = LruRedux::Cache.new(LOCATION_CACHE_SIZE)
      @weather_cache = LruRedux::TTL::Cache.new(WEATHER_CACHE_SIZE, WEATHER_CACHE_TTL)

      @mode = mode
      @polling_thread = Thread.new { polling_loop } if @mode == :polling
    end

    private

    def get(path, query)
      uri = URI.parse("https://api.openweathermap.org")
      uri.path = path
      uri.query = URI.encode_www_form(query)

      res = Net::HTTP.get_response(uri)
      body = JSON.parse(res.body)

      case res.code.to_f
      when 200 then body
      when 400..499 then raise RequestError, "#{body["message"]}"
      when 500..599 then raise ServerError, "#{body["message"]}"
      else raise Error, "#{body["message"]}"
      end
    end

    def get_weather_request(location)
      res = get("/data/2.5/weather", {lat: location[:lat], lon: location[:lon], appid: @api_key, units: @units.to_s})

      weather_data = res["weather"].first
      temperature_data = res["main"]
      wind_data = res["wind"]
      sys_data = res["sys"]

      weather = {
        weather: {
          main: weather_data["main"],
          description: weather_data["description"]
        },
        temperature: {
          temp: temperature_data["temp"],
          feels_like: temperature_data["feels_like"]
        },
        visibility: res["visibility"],
        wind: {
          speed: wind_data["speed"]
        },
        datetime: res["dt"],
        sys: {
          sunrise: sys_data["sunrise"],
          sunset: sys_data["sunset"]
        },
        timezone: res["timezone"],
        name: res["name"]
      }

      @weather_cache[location] = weather

      weather
    end

    def get_location_request(city)
      res = get("/geo/1.0/direct", {q: city, limit: 1, appid: @api_key})

      raise Error, "Provided city was not found" if res[0].nil?

      location = {lat: res[0]["lat"], lon: res[0]["lon"]}

      @location_cache[city] = location

      location
    end

    def get_location(city)
      location = @location_cache[city]

      return location unless location.nil?

      get_location_request(city)
    end

    def update_weather
      @location_cache.to_a.each do |city|
        get_weather_request(city[1])
      end
    end

    def polling_loop
      loop do
        begin
          update_weather
        rescue Error => e
          puts "Error during polling: #{e.message}"
        end

        sleep POLLING_RATE
      end
    end
  end
end
