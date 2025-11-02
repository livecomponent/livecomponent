namespace :test do
  desc "Run system tests"
  task :system do
    ENV["RAILS_ENV"] = "test"

    # Run all system tests
    Dir.glob("test/system/**/*_test.rb").each { |file| require_relative "../../#{file}" }
  end
end

# Make test:system the default for `rake test`
task test: "test:system"
