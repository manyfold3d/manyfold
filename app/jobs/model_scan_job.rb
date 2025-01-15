require "shellwords"

class ModelScanJob < ApplicationJob
  queue_as :scan

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
    library.list_files(glob)
  end

  def perform(model_id, include_all_subfolders: false)
    model = Model.find(model_id)
    return if Problem.create_or_clear(model, :missing, !model.exists_on_storage?)
    # For each file in the model, create a file object
    file_list(model.path, model.library, include_all_subfolders: include_all_subfolders).each do |filename|
      # Create the file
      file = model.model_files.find_or_create_by(filename: filename.gsub(model.path + "/", ""))
      ModelFileScanJob.perform_later(file.id) if file.valid?
    end
    # Set tags and default files
    model.model_files.reload
    model.preview_file = model.model_files.min_by { |it| preview_priority(it) } unless model.preview_file
    if model.tags.empty?
      model.generate_tags_from_directory_name! if SiteSettings.model_tags_tag_model_directory_name
      if SiteSettings.model_tags_auto_tag_new.present?
        model.tag_list << SiteSettings.model_tags_auto_tag_new
      end
    end
    if !model.creator_id && SiteSettings.parse_metadata_from_path
      model.parse_metadata_from_path
    end
    model.save!
    # Integrity check will run automatically after save
  end

  def preview_priority(file)
    return 0 if file.is_image?
    return 1 if file.is_renderable?
    100
  end
end
