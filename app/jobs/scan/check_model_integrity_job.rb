class Scan::CheckModelIntegrityJob < ApplicationJob
  queue_as :scan

  def perform(model)
    Problem.create_or_clear model, :empty, (model.model_files.count == 0)
    Problem.create_or_clear model, :nesting, model.contains_other_models?
  end
end
