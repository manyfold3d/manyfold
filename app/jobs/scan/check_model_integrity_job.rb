class Scan::CheckModelIntegrityJob < ApplicationJob
  queue_as :scan

  def perform(model_id)
    model = Model.find(model_id)
    return if model.nil?
    Problem.create_or_clear(model, :missing, !File.exist?(File.join(model.library.path, model.path)))
    Problem.create_or_clear model, :empty, (model.model_files.count == 0)
    Problem.create_or_clear model, :nesting, model.contains_other_models?
    model.model_files.each do |f|
      Problem.create_or_clear(f, :missing, !File.exist?(File.join(model.library.path, model.path, f.filename)))
    end
  end
end
