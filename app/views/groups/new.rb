# frozen_string_literal: true

class Views::Groups::New < Views::Groups::Form
  def view_template
    PageTitle title: t("views.groups.new.title"), breadcrumbs: {
      Creator.model_name.human(count: 100) => creators_path,
      @creator.name => creator_path(@creator),
      t("views.groups.index.title") => creator_groups_path(@creator)
    }
    super
  end
end
