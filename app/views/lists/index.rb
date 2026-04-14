# frozen_string_literal: true

class Views::Lists::Index < Views::Base
  def initialize(lists:)
    @lists = lists
  end

  def view_template
    PageTitle title: t("views.lists.index.title")
    p { t("views.lists.index.description") }
    table class: "table table-striped" do
      tr do
        th { List.human_attribute_name :name }
        th { ListItem.model_name.human(count: 100) }
        th
      end
      @lists.each do |list|
        tr do
          td { link_to (list.special ? t(list.name) : list.name), list_path(list) }
          td { list.list_items.count }
          td { GoButton label: t("views.lists.edit.title"), href: edit_list_path(list), icon: "pencil", variant: :secondary }
        end
      end
    end
    GoButton icon: "plus-circle", label: t("views.lists.new.title"), href: new_list_path, variant: :primary
  end
end
