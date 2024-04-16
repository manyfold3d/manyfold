class Scan::CheckModelIntegrityJob < ApplicationJob
  queue_as :scan

  def perform(model_id)
    begin
      model = Model.find(model_id)
    rescue ActiveRecord::RecordNotFound
      logger.warn "Scan::CheckModelIntegrityJob aborted, invalid Model ID #{model_id}"
      return
    end
    Problem.create_or_clear(model, :missing, !File.exist?(File.join(model.library.path, model.path)))
    Problem.create_or_clear model, :empty, (model.model_files.count == 0)
    Problem.create_or_clear model, :nesting, model.contains_other_models?
    Problem.create_or_clear model, :no_image, model.image_files.empty?
    Problem.create_or_clear model, :no_3d_model, model.three_d_files.empty?
    model.model_files.each do |f|
      Problem.create_or_clear(f, :missing, !File.exist?(File.join(model.library.path, model.path, f.filename)))
    end
  end
end
