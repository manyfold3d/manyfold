# frozen_string_literal: true

class Views::Lists::Show < Views::Base
  def initialize(list:)
    @list = list
  end

  def view_template
    PageTitle title: t("views.lists.show.title", name: @list.name), breadcrumbs: {
      t("views.lists.index.title") => lists_path
    }
    p { t("views.lists.show.description") }
    table class: "table table-striped" do
      tr do
        th { Model.model_name.human(count: 100) }
      end
      @list.models.each do |model|
        tr do
          td { link_to model.name, model_path(model) }
        end
      end
    end
    GoButton label: t("views.lists.edit.title"), href: edit_list_path(@list), icon: "pencil", variant: :primary
  end
end
