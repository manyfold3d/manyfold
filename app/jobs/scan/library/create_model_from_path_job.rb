class Scan::Library::CreateModelFromPathJob < ApplicationJob
  queue_as :scan
  unique :until_executed

  def perform(library_id, path, include_all_subfolders: false)
    library = Library.find(library_id)
    return if library.nil?
    new_model_properties = {
      # Initial best guess at name, this might be overwritten later by path parser
      name: File.basename(path).humanize.tr("+", " ").careful_titleize
    }
    model = library.models.create_with(new_model_properties).find_or_create_by(path: path.trim_path_separators)
    if model.valid?
      model.add_new_files_later(include_all_subfolders: include_all_subfolders)
    else
      Rails.logger.error(model.inspect)
      Rails.logger.error(model.errors.full_messages.inspect)
    end
  end
end
