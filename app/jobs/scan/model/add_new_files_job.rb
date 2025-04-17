require "shellwords"

class Scan::Model::AddNewFilesJob < ApplicationJob
  queue_as :scan
  unique :until_executed

  def file_list(model_path, library, include_all_subfolders: false)
    glob = include_all_subfolders ?
      [File.join(Shellwords.escape(model_path), "**", ApplicationJob.file_pattern)] :
      [File.join(Shellwords.escape(model_path), ApplicationJob.file_pattern)] +
        ApplicationJob.common_subfolders.map do |name, pattern|
          File.join(
            Shellwords.escape(model_path),
            ApplicationJob.case_insensitive_glob_string(name),
            pattern
          )
        end
    library.list_files(glob) + library.list_files(File.join(Shellwords.escape(model_path), "datapackage.json"))
  end

  def perform(model_id, include_all_subfolders: false)
    model = Model.find(model_id)
    return if model.remote?
    return if Problem.create_or_clear(model, :missing, !model.exists_on_storage?)
    # For each file in the model, create a file object
    file_list(model.path, model.library, include_all_subfolders: include_all_subfolders).each do |filename|
      # Create the file
      file = model.model_files.find_or_create_by(filename: filename.gsub(model.path + "/", ""))
      file.parse_metadata_later if file.valid? && file.filename != "datapackage.json"
    end
    model.parse_metadata_later
  end
end
