# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "owm_sdk"

require "webmock/minitest"
require "minitest/stub_const"
require "minitest/autorun"
