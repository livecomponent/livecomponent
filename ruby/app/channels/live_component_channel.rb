# frozen_string_literal: true

# Transport adapter for ActionCable. Owns the cable envelope
# (payload + request_id); the Renderer owns everything between.
# Responses go back over this connection only — no global stream.
class LiveComponentChannel < ActionCable::Channel::Base
  def receive(data)
    request_id = data["request_id"] if data.respond_to?(:[])

    result =
      begin
        LiveComponent::Renderer.render(data["payload"])
      rescue StandardError => e
        LiveComponent::Renderer::Failure.new(
          message: e.message, error_class: e.class.name, backtrace: e.backtrace || []
        )
      end

    case result
    in LiveComponent::Renderer::Success(payload:)
      transmit({ payload: payload, request_id: request_id })
    in LiveComponent::Renderer::Failure(message:, backtrace:)
      transmit({ error: { message: message, backtrace: backtrace }, request_id: request_id })
    end
  end
end
