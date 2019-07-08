# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'portmone'

require 'minitest/autorun'
require 'vcr'
require 'faraday'
require 'pry'

VCR.configure do |config|
  config.hook_into :faraday
  config.before_record do |item|
    item.response.body.force_encoding('UTF-8')
  end
  config.cassette_library_dir = 'test/vcr_cassettes'
  config.allow_http_connections_when_no_cassette = true
end
