# frozen_string_literal: true

module OwmSdk
  module Request
    private

    def get(path, query)
      uri = URI.parse("https://api.openweathermap.org")
      uri.path = path
      uri.query = URI.encode_www_form(query)

      res = Net::HTTP.get_response(uri)
      body = JSON.parse(res.body)

      case res.code.to_f
      when 200 then body
      when 400..499 then raise OwmSdk::Errors::RequestError, (body["message"]).to_s
      when 500..599 then raise OwmSdk::Errors::ServerError, (body["message"]).to_s
      else raise Error, (body["message"]).to_s
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
  end
end
