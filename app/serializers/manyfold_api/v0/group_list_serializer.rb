module ManyfoldApi::V0
  class GroupListSerializer < ApplicationSerializer
    def initialize(creator, groups)
      @creator = creator
      super(groups)
    end

    def groups_path(options = {})
      Rails.application.routes.url_helpers.creator_groups_path(@creator, options)
    end

    def serialize
      {
        "@context": context,
        "@id": groups_path,
        "@type": "hydra:Collection",
        totalItems: @object.total_count,
        member: @object.map { |group|
          {
            "@id": Rails.application.routes.url_helpers.creator_group_path(@creator, group),
            name: group.name
          }
        },
        view: {
          "@id": groups_path(page: @object.current_page),
          "@type": "hydra:PartialCollectionView",
          first: groups_path(page: 1),
          previous: (groups_path(page: @object.prev_page) if @object.prev_page),
          next: (groups_path(page: @object.next_page) if @object.next_page),
          last: groups_path(page: @object.total_pages)
        }.compact
      }
    end
  end
end
