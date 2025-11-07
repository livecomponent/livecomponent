# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require_relative "dummy/config/environment"
require "rails/test_help"

require "capybara/rails"
require "capybara/cuprite"

require_relative "./test_helpers/retry"

# Load the schema for the in-memory test database
ActiveRecord::Schema.verbose = false
ActiveRecord::Tasks::DatabaseTasks.load_schema_current(:ruby, File.expand_path("dummy/db/schema.rb", __dir__))

class TestCase < ActiveSupport::TestCase
  include ViewComponent::TestHelpers
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite, screen_size: [1400, 1400], options: {
    headless: !ENV["SHOW_BROWSER"]
  }
end
