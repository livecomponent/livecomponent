# frozen_string_literal: true

module LiveComponent
  class InlineSerializer
    class Builder
      def serialize(&block)
        @serializer_proc = block
      end

      def deserialize(&block)
        @deserializer_proc = block
      end

      def to_serializer
        InlineSerializer.new(@serializer_proc, @deserializer_proc)
      end
    end

    def initialize(serializer_proc, deserializer_proc)
      @serializer_proc = serializer_proc
      @deserializer_proc = deserializer_proc
    end

    def serialize(object)
      @serializer_proc ? @serializer_proc.call(object) : object
    end

    def deserialize(hash)
      @deserializer_proc ? @deserializer_proc.call(hash) : hash
    end
  end
end
