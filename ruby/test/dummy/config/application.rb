require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)
require "live_component"

module Dummy
  class Application < Rails::Application
    config.load_defaults 8.0
    config.autoload_lib(ignore: %w(tasks))
  end
end
