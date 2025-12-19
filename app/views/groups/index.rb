# frozen_string_literal: true

class Views::Groups::Index < Views::Base
  def initialize(creator:, groups:)
    @creator = creator
    @groups = groups
  end

  def view_template
    PageTitle title: t("views.groups.index.title"), breadcrumbs: {
      Creator.model_name.human(count: 100) => creators_path,
      @creator.name => creator_path(@creator)
    }
    p { t("views.groups.index.description") }
    table class: "table table-striped" do
      tr do
        th { Group.human_attribute_name :name }
        th { Group.human_attribute_name :memberships }
        th { Group.human_attribute_name :description }
        th { Group.human_attribute_name :typed_id }
        th
      end
      @groups.each do |group|
        tr do
          td { group.name }
          td { t("views.groups.index.member_count", count: group.members.count) }
          td { group.description }
          td { CopyableText text: group.typed_id, label: t("views.groups.index.copy") }
          td { GoButton label: t("views.groups.edit.title"), href: edit_creator_group_path(@creator, group), icon: "pencil", variant: :primary }
        end
      end
    end
    GoButton href: new_creator_group_path(@creator), label: t("views.groups.new.title"), variant: :primary
  end
end
