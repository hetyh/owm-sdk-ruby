# frozen_string_literal: true

module OwmSdk
  class Weather
    include Request

    attr_accessor(*Config::ATTRIBUTES)

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

    def initialize(config = {})
      OwmSdk::Config::ATTRIBUTES.each do |key|
        send(:"#{key}=", config[key] || OwmSdk.config.send(key))
      end

      validate_configuration(config)

      @logger = Logger.new(STDOUT)

      @location_cache = LruRedux::Cache.new(LOCATION_CACHE_SIZE)
      @weather_cache = LruRedux::TTL::Cache.new(WEATHER_CACHE_SIZE, WEATHER_CACHE_TTL)

      @polling_thread = Thread.new { polling_loop } if @mode == :polling
    end

    class << self
      def configure
        block_given? ? yield(Config) : Config
      end

      def config
        Config
      end
    end

    private

    def validate_configuration(config)
      validate_api_key(config[:api_key])
      validate_mode(config[:mode]) unless config[:mode].nil?
      validate_units(config[:units]) unless config[:units].nil?
    end

    def validate_api_key(api_key)
      raise ArgumentError, "API key cannot be nil or empty" if api_key.nil? || api_key.empty?
    end

    def validate_mode(mode)
      valid_modes = %w[on_demand polling]
      raise ArgumentError, "Invalid mode. Supported modes: #{valid_modes.join(", ")}" unless valid_modes.include?(mode)
    end

    def validate_units(units)
      valid_units = %w[standard metric imperial]

      unless valid_units.include?(units)
        raise ArgumentError,
          "Invalid units. Supported units: #{valid_units.join(", ")}"
      end
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
          @logger.error "Error during polling: #{e.message}"
        end

        sleep POLLING_RATE
      end
    end
  end
end
