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
        th { Model.model_name.human }
        th { ListItem.human_attribute_name(:created_at) }
      end
      @list.list_items.each do |item|
        next unless item.listable.is_a? Model
        tr do
          td { link_to item.listable.name, model_path(item.listable) }
          td { item.created_at.to_fs(:long_ordinal) }
        end
      end
    end
    GoButton label: t("views.lists.edit.title"), href: edit_list_path(@list), icon: "pencil", variant: :primary
  end
end
