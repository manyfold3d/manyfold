# frozen_string_literal: true

class Views::Groups::Form < Views::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(creator:, group:)
    @creator = creator
    @group = group
  end

  def view_template
    form_with model: [@creator, @group], class: "container-md tabular-form" do |form|
      Components::TextInputRow(form: form, attribute: :name, label: Group.human_attribute_name(:name))
      Components::RichTextInputRow(form: form, attribute: :description, label: Group.human_attribute_name(:description))
      div do
        form.submit class: "btn btn-primary"

        if @group.persisted? && policy(@group).destroy?
          link_to creator_group_path(@creator, @group), {
            method: :delete,
            class: "float-end btn btn-outline-danger",
            data: {confirm: translate(".confirm_destroy")}
          } do
            Icon(icon: "trash", label: t("general.delete"))
            whitespace
            span { t("general.delete") }
          end
        end
      end
    end
  end
end
