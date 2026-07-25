# frozen_string_literal: true

require "json"

module LiveComponent
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      if env["PATH_INFO"] == "/live_component/render"
        begin
          render_response(env)
        rescue Exception => e
          error_response(e)
        end
      else
        @app.call(env)
      end
    end

    private

    def render_response(env)
      raw_data = env["rack.input"].read
      data = JSON.parse(raw_data)
      payload, compressed = LiveComponent::Payload.decode_request(data["payload"])

      result = LiveComponent::RenderController.renderer.render(
        :show, assigns: { state: payload["state"], reflexes: payload["reflexes"] }, layout: false
      )

      result = LiveComponent::Payload.encode_response(result, compress: compressed)

      [200, { "Content-Type" => "text/html" }, [result]]
    end

    def error_response(e)
      body = <<~HTML
        #{e.message} (#{e.class.name})<br>
        #{e.backtrace.join("<br>")}
      HTML

      headers = {
        "Content-Type" => "text/html",
        "X-Live-Error-Message" => "#{e.message} (#{e.class.name})",
        "X-Live-Error-Backtrace-Json" => e.backtrace.to_json,
      }

      [500, headers, [body]]
    end
  end
end
