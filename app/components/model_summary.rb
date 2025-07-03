# frozen_string_literal: true

class Components::ModelSummary < Components::ModelCard
  def initialize(model:)
    @model = model
  end

  def view_template
    div class: "card" do
      div class: "card-body row" do
        div class: "col" do
          h5 { @model.name }
          span { @model.model_files.count }
          whitespace
          span { ModelFile.model_name.human count: @model.model_files.count }
          span { " : " }
          code { @model.path }
        end
        div(class: "col-auto") do
          credits
          div { @model.tags.map { |it| Tag(tag: it) } }
        end
      end
    end
  end
end
