# frozen_string_literal: true

require "json"

module LiveComponent
  # Transport adapter for HTTP. Owns the rack envelope; the Renderer
  # owns everything between decode and encode.
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      return @app.call(env) unless env["PATH_INFO"] == "/live_component/render"

      result =
        begin
          data = JSON.parse(env["rack.input"].read)
          Renderer.render(data["payload"])
        rescue StandardError => e
          Renderer::Failure.new(
            message: e.message, error_class: e.class.name, backtrace: e.backtrace || []
          )
        end

      case result
      in Renderer::Success(payload:)
        [200, { "Content-Type" => "text/html" }, [payload]]
      in Renderer::Failure
        error_response(result)
      end
    end

    private

    def error_response(failure)
      message = "#{failure.message} (#{failure.error_class})"


      body = <<~HTML
        #{message}<br>
        #{failure.backtrace.join("<br>")}
      HTML

      headers = {
        "Content-Type" => "text/html",
        "X-Live-Error-Message" => message,
        "X-Live-Error-Backtrace-Json" => failure.backtrace.to_json,
      }

      [500, headers, [body]]
    end
  end
end
