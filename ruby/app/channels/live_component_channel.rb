# frozen_string_literal: true

class LiveComponentChannel < ActionCable::Channel::Base
  def subscribed
    stream_from "live_component"
  end

  def receive(data)
    broadcast_response(data)
  rescue Exception => e
    broadcast_error(data, e)
  end

  private

  def broadcast_response(data)
    request_id = data["request_id"]
    payload, compressed = LiveComponent::Payload.decode_request(data["payload"])

    result = LiveComponent::RenderController.renderer.render(
      :show, assigns: { state: payload["state"], reflexes: payload["reflexes"] }, layout: false
    )

    result = LiveComponent::Payload.encode_response(result, compress: compressed)

    ActionCable.server.broadcast(
      "live_component",
      { payload: result, request_id: request_id }
    )
  end

  def broadcast_error(data, e)
    request_id = data["request_id"]
    payload = {
      message: e.message,
      backtrace: e.backtrace,
    }

    ActionCable.server.broadcast(
      "live_component",
      { error: payload, request_id: request_id }
    )
  end
end
