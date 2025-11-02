# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require_relative "../dummy/config/environment"
require "rails/test_help"

require "capybara/rails"
require "capybara/cuprite"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite, screen_size: [1400, 1400], options: {
    headless: !ENV["SHOW_BROWSER"]
  }
end
