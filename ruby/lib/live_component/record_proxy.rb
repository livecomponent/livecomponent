# frozen_string_literal: true

module LiveComponent
  class RecordProxy
    class << self
      def for(gid, attributes)
        proxy_mixins[gid.model_class] ||= Module.new.tap do |mod|
          mtds = (gid.model_class.column_names - ["id"]).map do |column_name|
            <<~RUBY
              def #{column_name}
                return @record.#{column_name} if @record

                if @attributes.include?("#{column_name}")
                  return @attributes["#{column_name}"]
                end

                load

                @record.#{column_name}
              end
            RUBY
          end

          mod.class_eval(mtds.join("\n"), __FILE__, __LINE__)
        end

        new(gid, attributes).tap do |proxy|
          proxy.singleton_class.include(proxy_mixins[gid.model_class])
        end
      end

      private

      def proxy_mixins
        @proxy_mixins ||= {}
      end
    end

    def initialize(gid, attributes)
      @gid = gid
      @attributes = attributes
    end

    def cached_attributes
      @attributes
    end

    def method_missing(method_name, *args, **kwargs, &block)
      load unless @record
      @record.send(method_name, *args, **kwargs, &block)
    end

    def load
      @record ||= GlobalID::Locator.locate(@gid)
    end

    def reload
      @record = GlobalID::Locator.locate(@gid)
    end

    def id
      @id ||= @gid.model_class.type_for_attribute("id").cast(@gid.model_id)
    end

    def to_global_id
      GlobalID.new(@gid.uri)
    end

    def to_signed_global_id
      SignedGlobalID.new(@gid.uri)
    end

    def to_model
      self
    end

    def to_param
      id.to_s
    end

    def persisted?
      true
    end
  end
end
