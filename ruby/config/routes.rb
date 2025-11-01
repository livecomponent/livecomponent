# frozen_string_literal: true

LiveComponent::Engine.routes.draw do
  post "/render", to: "render#show", as: "render"
end
