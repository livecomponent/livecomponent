# frozen_string_literal: true

module LiveComponent
  class ModelSerializer
    MODEL_SERIALIZER_KEY = "_lc_ar".freeze

    attr_reader :sign, :load, :attributes

    alias sign? sign
    alias load? load

    def self.make(...)
      new(...)
    end

    def initialize(sign: true, load: false, attributes: true)
      @sign = sign
      @attributes = attributes.is_a?(Array) ? attributes.map(&:to_s) : attributes
    end

    def serialize(object)
      gid = sign? ? object.to_signed_global_id : object.to_global_id

      { MODEL_SERIALIZER_KEY => { "gid" => gid.to_s, "signed" => sign? } }.tap do |result|
        object_attributes = if object.is_a?(RecordProxy)
          object.cached_attributes
        else
          object.attributes
        end

        attributes_hash = if attributes.is_a?(Array)
          object_attributes.slice(*attributes)
        elsif attributes  # true case
          object_attributes
        end

        if attributes_hash
          attributes_hash.each_pair do |k, v|
            result[k] = LiveComponent.serializer.serialize(v)
          end
        end
      end
    rescue URI::GID::MissingModelIdError
      raise SerializationError, "Unable to serialize #{object.class} " \
        "without an id. (Maybe you forgot to call save?)"
    end

    def deserialize(hash)
      gid_attrs = hash[MODEL_SERIALIZER_KEY]
      gid = gid_attrs["gid"]
      signed = gid_attrs["signed"]

      if load?
        if signed
          GlobalID::Locator.locate_signed(gid)
        else
          GlobalID::Locator.locate(gid)
        end
      else
        parsed_gid = signed ? SignedGlobalID.parse(gid) : GlobalID.parse(gid)
        RecordProxy.for(parsed_gid, hash.except("_lc_ar"))
      end
    end
  end
end
