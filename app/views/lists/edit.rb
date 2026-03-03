# frozen_string_literal: true

class Views::Lists::Edit < Views::Lists::Form
  def view_template
    PageTitle title: t("views.lists.edit.title"), breadcrumbs: {
      List.model_name.human(count: 100) => lists_path,
      @list.name => list_path(@list)
    }
    super
  end
end
