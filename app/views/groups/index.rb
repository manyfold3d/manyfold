# frozen_string_literal: true

class Views::Groups::Index < Views::Base
  def initialize(creator:, groups:)
    @creator = creator
    @groups = groups
  end

  def view_template
    PageTitle title: t(".title"), breadcrumbs: {
      Creator.model_name.human(count: 100) => creators_path,
      @creator.name => creator_path(@creator)
    }
    p { t("views.groups.index.description") }
    table class: "table table-striped" do
      tr do
        th { t("views.groups.index.name") }
        th { t("views.groups.index.membership") }
        th { t("views.groups.index.typed_id") }
        th
      end
      @groups.each do |group|
        tr do
          td { group.name }
          td { t("views.groups.index.member_count", count: group.members.count) }
          td { CopyableText text: group.typed_id, label: t("views.groups.index.copy") }
          td { GoButton label: t("views.groups.edit.title"), href: edit_creator_group_path(@creator, group), icon: "pencil", variant: :primary }
        end
      end
    end
    GoButton href: new_creator_group_path(@creator), label: t("views.groups.new.title"), variant: :primary
  end
end
