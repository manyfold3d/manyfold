class Scan::CreateModelJob < ApplicationJob
  queue_as :scan

  def perform(library_id, path)
    library = Library.find(library_id)
    return if library.nil?
    new_model_properties = {
      # Initial best guess at name, this might be overwritten later by path parser
      name: File.basename(path).humanize.tr("+", " ").titleize
    }
    model = library.models.create_with(new_model_properties).find_or_create_by(path: path.trim_path_separators)
    if model.valid?
      ModelScanJob.perform_later(model.id)
    else
      Rails.logger.error(model.inspect)
      Rails.logger.error(model.errors.full_messages.inspect)
    end
  end
end
