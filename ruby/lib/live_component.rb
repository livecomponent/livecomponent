# frozen_string_literal: true

module LiveComponent
  autoload :Action,                 "live_component/action"
  autoload :Base,                   "live_component/base"
  autoload :BigDecimalSerializer,   "live_component/big_decimal_serializer"
  autoload :ControllerMethods,      "live_component/controller_methods"
  autoload :DateSerializer,         "live_component/date_serializer"
  autoload :DateTimeSerializer,     "live_component/date_time_serializer"
  autoload :DurationSerializer,     "live_component/duration_serializer"
  autoload :InlineSerializer,       "live_component/inline_serializer"
  autoload :Middleware,             "live_component/middleware"
  autoload :ModelSerializer,        "live_component/model_serializer"
  autoload :ModuleSerializer,       "live_component/module_serializer"
  autoload :ObjectSerializer,       "live_component/object_serializer"
  autoload :Payload,                "live_component/payload"
  autoload :RangeSerializer,        "live_component/range_serializer"
  autoload :RecordProxy,            "live_component/record_proxy"
  autoload :SafeDispatcher,         "live_component/safe_dispatcher"
  autoload :Serializer,             "live_component/serializer"
  autoload :TimeWithZoneSerializer, "live_component/time_with_zone_serializer"
  autoload :TagBuilder,             "live_component/tag_builder"
  autoload :Target,                 "live_component/target"
  autoload :TimeObjectSerializer,   "live_component/time_object_serializer"
  autoload :TimeSerializer,         "live_component/time_serializer"
  autoload :TimeWithZoneSerializer, "live_component/time_with_zone_serializer"
  autoload :React,                  "live_component/react"
  autoload :State,                  "live_component/state"
  autoload :Utils,                  "live_component/utils"

  class UnexpectedConstantError < StandardError; end
  class SerializationError < ArgumentError; end
  class SafeDispatchError < StandardError; end

  class << self
    def register_prop_serializer(name, klass)
      registered_prop_serializers[name] = klass
    end

    def registered_prop_serializers
      @registered_prop_serializers ||= {}
    end

    def serializer
      @serializer ||= Serializer.make
    end
  end
end

LiveComponent.register_prop_serializer(:model_serializer, LiveComponent::ModelSerializer)

if defined?(Rails)
  require "live_component/engine"
end

require File.join(File.dirname(__dir__), "ext", "view_component_patch")
