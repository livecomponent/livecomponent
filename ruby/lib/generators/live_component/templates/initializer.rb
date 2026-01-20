require "live_component"

Rails.application.config.middleware.insert_before(0, LiveComponent::Middleware)
