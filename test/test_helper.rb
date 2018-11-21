# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'portmone'

require 'minitest/autorun'
require 'vcr'
require 'webmock/minitest'
require 'pry'

VCR.configure do |config|
  config.cassette_library_dir = 'test/vcr_cassettes'
  config.hook_into :webmock
end
