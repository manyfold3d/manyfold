module Components::Renderers
  class Base < Components::Base
    def self.supports?(file)
      raise NotImplementedError
    end

    def initialize(file:, derivative: nil)
      @file = file
      @derivative = derivative
    end

    def view_template
      raise NotImplementedError
    end
  end
end
