# frozen_string_literal: true

module LiveComponent
  # The single server-side render entry point behind every transport adapter.
  # Takes an encoded Payload, returns Success(payload) or Failure.
  class Renderer
    Success = Data.define(:payload)
    Failure = Data.define(:message, :error_class, :backtrace)

    class << self
      def render(encoded_payload)
        payload, compressed = Payload.decode_request(encoded_payload)

        html = RenderController.renderer.render(
          RenderComponent.new(payload["state"], payload["reflexes"]),
          layout: false
        )

        Success.new(payload: Payload.encode_response(html, compress: compressed))
      rescue StandardError => e
        Failure.new(
          message: e.message,
          error_class: e.class.name,
          backtrace: e.backtrace || []
        )
      end
    end
  end
end
