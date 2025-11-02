# This file is used by Rack-based servers to start the application.

require_relative "config/environment"
require "live_component/middleware"

use LiveComponent::Middleware
run Rails.application
