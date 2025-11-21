# frozen_string_literal: true

class LiveComponentChannel < ActionCable::Channel::Base
  def subscribed
    stream_from "live_component"
  end

  def receive(data)
    request_id = data["request_id"]
    payload = LiveComponent::Payload.decode(data["payload"])

    result = LiveComponent::RenderController.renderer.render(
      :show, assigns: { state: payload["state"], reflexes: payload["reflexes"] }, layout: false
    )

    result = LiveComponent::Payload.encode(result)

    ActionCable.server.broadcast(
      "live_component",
      { payload: result, request_id: request_id }
    )
  end
end
