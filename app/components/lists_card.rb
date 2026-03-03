# frozen_string_literal: true

class Components::ListsCard < Components::Base
  include Phlex::Rails::Helpers::LinkTo

  register_value_helper :policy_scope

  def initialize(listable:)
    @listable = listable
  end

  def render?
    @listable.present?
  end

  def before_template
    @all_lists = policy_scope(List).all
    @on_lists, @off_lists = @all_lists.partition { |it| @listable.in? it.models }
  end

  def view_template
    Card title: t("components.lists_card.title"), variant: :secondary do
      div class: "card-text" do
        on_lists if @on_lists.any?
        add_dropdown
      end
    end
  end

  private

  def add_path(list:)
    list_path(list,
      list: {
        list_items_attributes: [
          {listable_type: @listable.model_name, listable_id: @listable.id}
        ]
      })
  end

  def remove_path(list:)
    list_path(list,
      list: {
        list_items_attributes: [
          {id: list.list_items.find_by(listable: @listable), _destroy: "1"}
        ]
      })
  end

  def add_dropdown
    div class: "btn-group" do
      button type: "button",
        class: "btn btn-secondary mt-1 me-1 dropdown-toggle",
        data: {
          bs_toggle: "dropdown"
        },
        aria: {
          expanded: false,
          haspopup: "menu",
          controls: "lists-menu"
        } do
        t("components.lists_card.add_to_list")
      end
      ul class: "dropdown-menu", role: "menu", id: "lists-menu" do
        @off_lists.map do |list|
          DropdownItem label: list.name, path: add_path(list: list), method: :patch
        end
        DropdownDivider() if @off_lists.any?
        DropdownItem icon: "plus-circle", label: t("views.lists.new.title"), path: new_list_path
      end
    end
  end

  def on_lists
    span { t("components.lists_card.on_lists") }
    ul do
      @on_lists.map do |it|
        li do
          link_to(it.name, list_path(it))
          DoButton(icon: "trash", label: t("components.lists_card.remove"), href: remove_path(list: it), method: :patch, variant: :danger)
        end
      end
    end
  end
end
