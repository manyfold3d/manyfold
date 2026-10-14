# frozen_string_literal: true

class Components::Editors::PlaintextForm < Components::Base
  include Phlex::Rails::Helpers::FormTag
  include Phlex::Rails::Helpers::TextAreaTag
  include Phlex::Rails::Helpers::SubmitTag

  def initialize(file:)
    @file = file
  end

  def view_template
    form_tag model_model_file_raw_path(@file.model, @file.filename), method: :put, class: "container-md" do
      div class: "mb-3" do
        text_area_tag :body, @file.attachment.read, class: "form-control", rows: "20"
      end

      div class: "form-save-button" do
        submit_tag
      end
    end
  end
end
