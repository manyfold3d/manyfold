class Scan::Model::CheckForProblemsJob < ApplicationJob
  queue_as :scan
  unique :until_executed

  def perform(model_id)
    model = Model.find(model_id)
    return if model.remote?
    Problem.create_or_clear(model, :missing, !model.exists_on_storage?)
    Problem.create_or_clear model, :empty, (model.model_files.count == 0)
    Problem.create_or_clear model, :nesting, model.contains_other_models?
    Problem.create_or_clear model, :no_image, model.image_files.empty?
    Problem.create_or_clear model, :no_3d_model, model.three_d_files.empty?
    Problem.create_or_clear model, :no_license, model.license.blank?
    Problem.create_or_clear model, :no_links, model.links.empty?
    Problem.create_or_clear model, :no_creator, model.creator.nil?
    Problem.create_or_clear model, :no_tags, model.tag_list.empty?
    Problem.create_or_clear model, :file_naming, (model.needs_organizing? && !model.contains_other_models?), note: model.formatted_path
    model.model_files.each do |f|
      Problem.create_or_clear(f, :missing, !f.exists_on_storage?)
    end
  end
end
