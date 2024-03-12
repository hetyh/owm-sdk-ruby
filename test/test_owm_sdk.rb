# frozen_string_literal: true

require "test_helper"

location_response_file = File.new("test/city_location_response.txt")
weather_response_file = File.new("test/city_weather_response.txt")

WebMock.stub_request(:get, Addressable::Template.new("https://api.openweathermap.org/geo/1.0/direct{?appid,limit,q}")).to_return(location_response_file)
WebMock.stub_request(:get, Addressable::Template.new("https://api.openweathermap.org/data/2.5/weather{?appid,lat,lon,units}")).to_return(weather_response_file)

describe OwmSdk::Weather do
  describe "#get_weather" do
    it "should return weather information in on_demand mode" do
      client = OwmSdk::Weather.new(api_key: "API_KEY", units: "standard", mode: "on_demand")

      result = client.get_weather("London")

      assert_equal(
        {
          weather: {
            main: "Drizzle",
            description: "light intensity drizzle"
          },
          temperature: {
            temp: 286.07,
            feels_like: 285.85
          },
          visibility: 3300,
          wind: {speed: 5.14},
          datetime: 1_710_257_919,
          sys: {
            sunrise: 1_710_224_446,
            sunset: 1_710_266_385
          },
          timezone: 0,
          name: "London"
        }, result
      )

      assert_equal(client.instance_variable_get(:@location_cache).to_a, [["London", {lat: 51.5073219, lon: -0.1276474}]])
    end
  end
end
