# frozen_string_literal: true

module LiveComponent
  autoload :Action,            "live_component/action"
  autoload :Base,              "live_component/base"
  autoload :ControllerMethods, "live_component/controller_methods"
  autoload :DefaultSerializer, "live_component/default_serializer"
  autoload :InlineSerializer,  "live_component/inline_serializer"
  autoload :ObjectSerializer,  "live_component/object_serializer"
  autoload :Middleware,        "live_component/middleware"
  autoload :ModelSerializer,   "live_component/model_serializer"
  autoload :RecordProxy,       "live_component/record_proxy"
  autoload :SafeDispatcher,    "live_component/safe_dispatcher"
  autoload :TagBuilder,        "live_component/tag_builder"
  autoload :Target,            "live_component/target"
  autoload :React,             "live_component/react"
  autoload :State,             "live_component/state"
  autoload :Utils,             "live_component/utils"

  class << self
    def register_prop_serializer(name, klass)
      registered_prop_serializers[name] = klass
    end

    def registered_prop_serializers
      @registered_prop_serializers ||= {}
    end

    def default_serializer
      DefaultSerializer.instance
    end
  end
end

LiveComponent.register_prop_serializer(:model_serializer, LiveComponent::ModelSerializer)

if defined?(Rails)
  require "live_component/engine"
end

require File.join(File.dirname(__dir__), "ext", "view_component_patch")
