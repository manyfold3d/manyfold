# frozen_string_literal: true

class Views::Lists::New < Views::Lists::Form
  def view_template
    PageTitle title: t("views.lists.new.title"), breadcrumbs: {
      List.model_name.human(count: 100) => lists_path
    }
    super
  end
end
