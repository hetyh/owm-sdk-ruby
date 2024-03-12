# frozen_string_literal: true

require "test_helper"

location_response = File.new("test/city_location_response.txt").read
weather_response = File.new("test/city_weather_response.txt").read
weather_updated_response = File.new("test/city_weather_updated_response.txt").read

location_url = Addressable::Template.new("https://api.openweathermap.org/geo/1.0/direct{?appid,limit,q}")
weather_url = Addressable::Template.new("https://api.openweathermap.org/data/2.5/weather{?appid,lat,lon,units}")

weather_expected = {
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
  datetime: 1710257919,
  sys: {
    sunrise: 1710224446,
    sunset: 1710266385
  },
  timezone: 0,
  name: "London"
}

weather_updated_expected = {
  weather: {
    main: "Drizzle",
    description: "light intensity drizzle"
  },
  temperature: {
    temp: 283.07,
    feels_like: 281.85
  },
  visibility: 3300,
  wind: {speed: 5.14},
  datetime: 1710257919,
  sys: {
    sunrise: 1710224446,
    sunset: 1710266385
  },
  timezone: 0,
  name: "London"
}

location_expected = {lat: 51.5073219, lon: -0.1276474}

describe OwmSdk::Weather do
  describe "#get_weather" do
    it "should return weather information in on_demand mode" do
      WebMock.stub_request(:get, location_url).to_return(location_response)
      WebMock.stub_request(:get, weather_url).to_return(weather_response)

      client = OwmSdk::Weather.new(api_key: "API_KEY", units: "standard", mode: "on_demand")

      result = client.get_weather("London")

      assert_equal(weather_expected, result)

      assert_equal(client.instance_variable_get(:@location_cache).to_a,
        [["London", location_expected]])

      assert_equal(client.instance_variable_get(:@weather_cache).to_a,
        [[location_expected, weather_expected]])
    end

    it "should return weather information in polling mode" do
      WebMock.stub_request(:get, location_url).to_return(location_response)
      WebMock.stub_request(:get, weather_url).to_return(weather_response)

      OwmSdk::Weather.stub_const(:POLLING_RATE, 0.25) do
        client = OwmSdk::Weather.new(api_key: "API_KEY", units: "standard", mode: "polling")
        client.get_weather("London")

        WebMock.stub_request(:get, weather_url).to_return(weather_updated_response)
        sleep 0.5

        res = client.get_weather("London")
        assert_equal(weather_updated_expected, res)
      end
    end
  end
end
