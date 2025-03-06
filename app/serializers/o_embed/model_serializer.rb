module OEmbed
  class ModelSerializer < ApplicationSerializer
    def serialize
      {
        type: "rich"
      }.merge(basic_properties)
    end
  end
end
