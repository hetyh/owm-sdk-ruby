# frozen_string_literal: true

require_relative "owm_sdk/version"

require "lru_redux"

require "uri"
require "net/http"
require "json"

module OwmSdk
  class Error < StandardError; end

  class Weather
    def get_weather(city)
      location = get_location(city)

      weather_cached = @weather_cache[location]
      return weather_cached unless weather_cached.nil?

      weather = get_weather_request(location)
      return weather unless weather.nil?

      Kernel.raise Error, "Weather data for provided city was not found"
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
      uri = URI.parse("https://api.openweathermap.org")
      uri.path = path
      uri.query = URI.encode_www_form(query)

      res = Net::HTTP.get_response(uri)
      body = JSON.parse(res.body)
      raise Error, "Got HTTP response #{res.code}, message: '#{body["message"]}'" unless res.code == "200"

      body
    end

    def get_weather_request(location)
      res = get("/data/2.5/weather", {lat: location[:lat], lon: location[:lon], appid: @api_key, units: @units.to_s})

      weather_data = res["weather"].first
      temperature_data = res["main"]
      wind_data = res["wind"]
      sys_data = res["sys"]

      weather = {
        "weather" => {
          "main" => weather_data["main"],
          "description" => weather_data["description"]
        },
        "temperature" => {
          "temp" => temperature_data["temp"],
          "feels_like" => temperature_data["feels_like"]
        },
        "visibility" => res["visibility"],
        "wind" => {
          "speed" => wind_data["speed"]
        },
        "datetime" => res["dt"],
        "sys" => {
          "sunrise" => sys_data["sunrise"],
          "sunset" => sys_data["sunset"]
        },
        "timezone" => res["timezone"],
        "name" => res["name"]
      }

      @weather_cache[location] = weather

      weather
    end

    def get_location_request(city)
      res = get("/geo/1.0/direct", {q: city, limit: 1, appid: @api_key})

      raise Error, "Provided city was not found" if res[0].nil?

      lat = res[0]["lat"]
      lon = res[0]["lon"]

      {lat: lat, lon: lon}
    end

    def get_location(city)
      location = @location_cache[city]

      return location unless location.nil?

      location = get_location_request(city)

      unless location.nil?
        @location_cache[city] = location
        return location
      end

      Kernel.raise Error, "oops"
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
          puts "Error during API requests: #{e.message}"
        end

        sleep @polling_rate
      end
    end
  end
end
