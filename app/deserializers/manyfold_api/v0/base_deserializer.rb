module ManyfoldApi::V0
  class BaseDeserializer
    def initialize(object)
      @object = object
    end

    def deserialize
      raise NotImplementedError
    end
  end
end
