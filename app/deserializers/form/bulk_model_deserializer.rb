module Form
  class BulkModelDeserializer < BaseDeserializer
    def deserialize
      return nil unless @params
      allowed = @params.permit(
        :creator,
        :library,
        :organize,
        :license,
        :sensitive,
        :indexable,
        :ai_indexable,
        collection_ids: [],
        add_tags: [],
        remove_tags: []
      )
      allowed = resolve_collections(allowed)
      allowed = resolve_creator(allowed)
      allowed = resolve_library(allowed, :library)
      allowed.compact_blank
    end
  end
end
