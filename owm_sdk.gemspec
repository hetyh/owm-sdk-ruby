# frozen_string_literal: true

require_relative "lib/owm_sdk/version"

Gem::Specification.new do |spec|
  spec.name = "owm_sdk"
  spec.version = OwmSdk::VERSION
  spec.authors = ["Alexander Kulichkov"]
  spec.email = ["hetyh2004@gmail.com"]

  spec.summary = "An example SDK for accessing OpenWeatherMap API"
  spec.homepage = "https://github.com/hetyh/owm-sdk-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/hetyh/owm-sdk-ruby"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "lru_redux", "~> 1.1"

  spec.add_development_dependency "webmock", "~> 3.23.0"
  spec.add_development_dependency "minitest-stub-const", "~> 0.6"
end
