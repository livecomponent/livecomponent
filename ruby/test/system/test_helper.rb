# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require_relative "../dummy/config/environment"

require "capybara/rails"
require "capybara/cuprite"
require "minitest/autorun"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite, screen_size: [1400, 1400]
end
