module ManyfoldApi::V0
  class GroupListSerializer < ApplicationSerializer
    def initialize(creator, groups, pager: nil)
      @creator = creator
      super(groups, pager: pager)
    end

    def groups_path(options = {})
      Rails.application.routes.url_helpers.creator_groups_path(@creator, options)
    end

    def serialize
      {
        "@context": context,
        "@id": groups_path,
        "@type": "hydra:Collection",
        totalItems: @pager.count,
        member: @object.map { |group|
          {
            "@id": Rails.application.routes.url_helpers.creator_group_path(@creator, group),
            name: group.name
          }
        },
        view: {
          "@id": groups_path(page: @pager.page),
          "@type": "hydra:PartialCollectionView",
          first: groups_path(page: 1),
          previous: (groups_path(page: @pager.previous) if @pager.previous),
          next: (groups_path(page: @pager.next) if @pager.next),
          last: groups_path(page: @pager.pages)
        }.compact
      }
    end
  end
end
