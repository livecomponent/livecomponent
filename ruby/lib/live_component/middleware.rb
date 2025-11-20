# frozen_string_literal: true

require "json"
require "base64"
require "zlib"

module LiveComponent
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      if env["PATH_INFO"] == "/live_component/render"
        raw_data = env["rack.input"].read
        data = JSON.parse(raw_data)
        payload = LiveComponent::Payload.decode(data["payload"])

        result = LiveComponent::RenderController.renderer.render(
          :show, assigns: { state: payload["state"], reflexes: payload["reflexes"] }, layout: false
        )

        return [200, { "Content-Type" => "text/html" }, [result]]
      end

      @app.call(env)
    end
  end
end
