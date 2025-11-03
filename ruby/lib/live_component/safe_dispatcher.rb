# frozen_string_literal: true

module LiveComponent
  class SafeDispatcher
    include Singleton

    def initialize
      @cache = ObjectSpace::WeakKeyMap.new
    end

    def send_safely(receiver, method_name, **kwargs)
      if receiver_defines_safe_method?(receiver, method_name)
        receiver.send(method_name, **kwargs)
      else
        raise(
          SafeDispatchError,
          "`#{method_name}' could not be called on an object of type '#{receiver.class.name}'. "\
            "Only public methods defined on classes that inherit from ViewComponent::Base "\
            "may be called."
        )
      end
    end

    def self.send_safely(...)
      instance.send_safely(...)
    end

    private

    def receiver_defines_safe_method?(receiver, method_name)
      receiver.class.ancestors.each do |ancestor|
        if ancestor_defines_safe_method?(ancestor, method_name)
          @cache[receiver.class] ||= Set.new
          @cache[receiver.class] << method_name

          return true
        end
      end

      false
    end

    def ancestor_defines_safe_method?(ancestor, method_name)
      return false unless ancestor < ViewComponent::Base

      public_mtds = @cache[ancestor] ||= Set.new

      if public_mtds.include?(method_name)
        return true
      end

      if ancestor.public_method_defined?(method_name, false)
        public_mtds << method_name
        return true
      end

      false
    end
  end
end
