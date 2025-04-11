module ManyfoldApi::V0
  class BaseDeserializer
    def initialize(object)
      @object = if object.is_a?(StringIO)
        JSON.parse(object.read)
      else
        object
      end
    end

    def deserialize
      raise NotImplementedError
    end
  end
end
