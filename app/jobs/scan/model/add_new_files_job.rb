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

  # For virtual models, only match files with the model's base name
  def virtual_file_list(model)
    base_name = model.virtual_basename
    folder = model.physical_folder
    suffix_pattern = "{,_#{ModelFile::SUPPORT_KEYWORDS.map { |k| ApplicationJob.case_insensitive_glob_string(k) }.join(",_")}}"
    ext_pattern = "{#{SupportedMimeTypes.indexable_extensions.map { |ext| ApplicationJob.case_insensitive_glob_string(ext) }.join(",")}}"
    file_pattern = "#{Shellwords.escape(base_name)}#{suffix_pattern}.#{ext_pattern}"
    # Match: basename.ext, basename_presupported.ext, etc.
    glob = if folder
      [File.join(Shellwords.escape(folder), file_pattern)]
    else
      # Root-level virtual model — files are at library root
      [file_pattern]
    end
    model.library.list_files(glob)
  end

  def perform(model_id, include_all_subfolders: false)
    model = Model.find(model_id)
    return if model.remote?
    return if Problem.create_or_clear(model, :missing, !model.exists_on_storage?)
    # For each file in the model, create a file object
    files = if model.virtual?
      virtual_file_list(model)
    else
      file_list(model.path, model.library, include_all_subfolders: include_all_subfolders)
    end
    base_path = model.virtual? ? model.physical_folder : model.path
    files.each do |filename|
      # Create the file — strip the base path prefix to get the relative filename
      relative_name = base_path ? filename.gsub(base_path + "/", "") : filename
      file = model.model_files.find_or_create_by(filename: relative_name)
      file.parse_metadata_later if file.valid? && file.filename != "datapackage.json"
    end
    model.parse_metadata_later
  end
end
