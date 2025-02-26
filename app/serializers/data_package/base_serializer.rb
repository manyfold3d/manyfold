module DataPackage
  class BaseSerializer
    def initialize(object)
      @object = object
    end

    def serialize
      raise NotImplementedError
    end
  end
end
