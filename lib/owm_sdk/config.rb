# frozen_string_literal: true

module OwmSdk
  module Config
    extend self

    ATTRIBUTES = %i[
      api_key
      mode
      units
    ].freeze

    attr_accessor(*Config::ATTRIBUTES)

    def reset
      self.api_key = nil
      self.mode = nil
      self.units = nil
    end
  end

  class << self
    def configure
      block_given? ? yield(Config) : Config
    end

    def config
      Config
    end
  end
end

OwmSdk::Config.reset
