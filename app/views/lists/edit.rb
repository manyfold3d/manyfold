# frozen_string_literal: true

class Views::Lists::Edit < Views::Lists::Form
  def view_template
    PageTitle title: t("views.lists.edit.title"), breadcrumbs: {
      t("views.lists.index.title") => lists_path,
      @list.name => list_path(@list)
    }
    super
  end
end
