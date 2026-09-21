module Form
  class BulkModelDeserializer < BaseDeserializer
    def deserialize
      return nil unless @params
      allowed = @params.permit(
        :creator_id,
        :new_library_id,
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
      allowed.compact_blank
    end
  end
end
