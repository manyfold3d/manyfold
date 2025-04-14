module ManyfoldApi::V0
  class BaseDeserializer
    def initialize(object)
      @object = object
    end

    def deserialize
      raise NotImplementedError
    end

    def self.schema_ref_name
      name.underscore.split("/").last.gsub("_deserializer", "_request")
    end

    def self.schema_ref
      {"$ref" => "#/components/schemas/#{schema_ref_name}"}
    end

    def self.schema
      raise NotImplementedError
    end
  end
end
