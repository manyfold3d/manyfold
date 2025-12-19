# frozen_string_literal: true

class Views::Groups::Form < Views::Base
  include Phlex::Rails::Helpers::FormWith

  register_output_helper :cocooned_container
  register_output_helper :cocooned_add_item_button

  def initialize(creator:, group:)
    @creator = creator
    @group = group
  end

  def before_template
    @group.memberships.build if @group.memberships.empty?
  end

  def view_template
    form_with model: [@creator, @group], class: "container-md tabular-form" do |form|
      Components::TextInputRow(form: form, attribute: :name, label: Group.human_attribute_name(:name))
      Components::RichTextInputRow(form: form, attribute: :description, label: Group.human_attribute_name(:description))

      # div { form.label :memberships }
      # div do
      #   cocooned_container id: "cocooned-memberships", data: {controller: "cocooned"} do
      #     form.fields_for :memberships do |f|
      #       render partial("membership_fields", f: f)
      #     end
      #   end
      #   cocooned_add_item_button t(".add"), form, :memberships,
      #     class: "btn btn-secondary",
      #     insertion_node: "#cocooned-memberships",
      #     insertion_method: "append"
      # end

      div do
        form.submit class: "btn btn-primary"

        if @group.persisted? && policy(@group).destroy?
          link_to creator_group_path(@creator, @group), {
            method: :delete,
            class: "float-end btn btn-outline-danger",
            data: {confirm: translate("views.groups.form.confirm_destroy")}
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
