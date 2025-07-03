# frozen_string_literal: true

class Components::ModelSummary < Components::Base
  def initialize(model:)
    @model = model
  end

  def view_template
    div class: "card" do
      div class: "card-body" do
        code(class: "float-end") { @model.path }
        div do
          span(class: "fs-4") { @model.name }
          whitespace
          span(class: "text-secondary") { t("components.model_summary.byline", creator: @model.creator.name) } if @model.creator
        end
        div(class: "float-end") { @model.tags.map { |it| Tag(tag: it) } }
        div do
          span { @model.model_files.count }
          whitespace
          span { ModelFile.model_name.human count: @model.model_files.count }
        end
      end
    end
  end
end
