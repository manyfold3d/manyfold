class Scan::Model::CheckForProblemsJob < ApplicationJob
  queue_as :scan
  unique :until_executed

  def perform(model_id)
    # Eager load associations to avoid N+1 queries
    model = Model.includes(:model_files, :links, :creator, :tags).find(model_id)
    return if model.remote?

    # Pre-load model_files to avoid multiple queries
    files = model.model_files.to_a

    # Pre-compute file type counts to avoid repeated filtering
    has_images = files.any?(&:is_image?)
    has_3d_models = files.any?(&:is_3d_model?)

    # Check model-level problems
    Problem.create_or_clear(model, :missing, !model.exists_on_storage?)
    Problem.create_or_clear model, :empty, files.empty?
    Problem.create_or_clear model, :nesting, model.contains_other_models?
    Problem.create_or_clear model, :no_image, !has_images
    Problem.create_or_clear model, :no_3d_model, !has_3d_models
    Problem.create_or_clear model, :no_license, model.license.blank?
    Problem.create_or_clear model, :no_links, model.links.empty?
    Problem.create_or_clear model, :no_creator, model.creator.nil?
    Problem.create_or_clear model, :no_tags, model.tag_list.empty?
    Problem.create_or_clear model, :file_naming, model.needs_organizing? && !model.contains_other_models?

    # Check file-level problems using already-loaded files
    files.each do |f|
      Problem.create_or_clear(f, :missing, !f.exists_on_storage?)
    end
  end
end
