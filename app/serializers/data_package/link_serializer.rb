module DataPackage
  class LinkSerializer < BaseSerializer
    def serialize
      {
        path: @object.url
      }.compact
    end
  end
end
