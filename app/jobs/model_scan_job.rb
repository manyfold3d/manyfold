require "shellwords"

class ModelScanJob < ApplicationJob
  queue_as :scan

  def file_list(model_path, include_all_subfolders: false)
    list = []
    Dir.open(model_path) do |dir|
      glob = include_all_subfolders ?
        [File.join(Shellwords.escape(dir.path), "**", ApplicationJob.file_pattern)] :
        [File.join(Shellwords.escape(dir.path), ApplicationJob.file_pattern)] +
          ApplicationJob.common_subfolders.map do |name, pattern|
            File.join(
              Shellwords.escape(dir.path),
              ApplicationJob.case_insensitive_glob_string(name),
              pattern
            )
          end
      list = Dir.glob(glob).uniq.filter { |x| File.file?(x) }
    end
    list
  end

  def perform(model_id, include_all_subfolders: false)
    model = Model.find(model_id)
    return if Problem.create_or_clear(model, :missing, !model.exist?)
    # For each file in the model, create a file object
    file_list(model.absolute_path, include_all_subfolders: include_all_subfolders).each do |filename|
      # Create the file
      file = model.model_files.find_or_create_by(filename: filename.gsub(model.absolute_path + "/", ""))
      ModelFileScanJob.perform_later(file.id) if file.valid?
    end
    # Set tags and default files
    model.model_files.reload
    model.preview_file = model.model_files.min_by { |x| x.is_image? ? 0 : 1 } unless model.preview_file
    if model.tags.empty?
      model.generate_tags_from_directory_name! if SiteSettings.model_tags_tag_model_directory_name
      if SiteSettings.model_tags_auto_tag_new.present?
        model.tag_list << SiteSettings.model_tags_auto_tag_new
        model.save!
      end
    end
    if !model.creator_id && SiteSettings.parse_metadata_from_path
      model.parse_metadata_from_path!
    end
    # Run integrity check once everything else is done
    Scan::CheckModelIntegrityJob.perform_later(model_id)
  end
end
