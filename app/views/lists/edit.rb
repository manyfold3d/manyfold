# frozen_string_literal: true

class Views::Lists::Edit < Views::Lists::Form
  def before_template
    @list_name = @list.special ? t(@list.name) : @list.name
  end

  def view_template
    PageTitle title: t("views.lists.edit.title"), breadcrumbs: {
      t("views.lists.index.title") => lists_path,
      @list_name => list_path(@list)
    }
    super
  end
end
