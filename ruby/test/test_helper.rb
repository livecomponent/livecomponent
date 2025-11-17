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

# Ensure browser cleanup happens when tests finish, regardless of test runner (m, rake, etc.)
Minitest.after_run do
  begin
    # Get the current driver and quit the browser before resetting sessions
    if Capybara.current_session.driver.respond_to?(:browser)
      browser = Capybara.current_session.driver.browser
      browser.quit if browser.respond_to?(:quit)
    end

    # Reset all Capybara sessions
    Capybara.reset_sessions!
  rescue StandardError => e
    # Ignore errors during cleanup
    puts "Warning: Error during browser cleanup: #{e.message}"
  end
end

# clear old vite test build
ViteRuby.commands.clobber

# remove compiled javascript files to prevent vite from including a stale build
FileUtils.rm_rf(File.expand_path(File.join(__dir__, "..", "..", "js", "dist")))
