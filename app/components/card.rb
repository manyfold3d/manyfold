# frozen_string_literal: true

class Components::Card < Components::Base
  include Phlex::Rails::Helpers::LinkTo

  register_value_helper :policy_scope

  def initialize(title:, variant:)
    @title = title
    @variant = variant
  end

  def view_template
    div class: "card mb-4" do
      div(class: "card-header text-white bg-#{@variant}") { @title }
      div(class: "card-body") do
        yield
      end
    end
  end
end
