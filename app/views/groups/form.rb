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
      div do
        form.submit
      end
    end
  end
end
