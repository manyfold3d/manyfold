# frozen_string_literal: true

module Views::Lists
  class New < Views::Lists::Form
    def view_template
      PageTitle title: t("views.lists.new.title"), breadcrumbs: {
        t("views.lists.index.title") => lists_path
      }
      super
    end
  end
end
