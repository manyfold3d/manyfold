require "shellwords"

class ModelScanJob < ApplicationJob
  queue_as :default

  def file_list(model_path)
    list = []
    Dir.open(model_path) do |dir|
      list = Dir.glob(
        [File.join(Shellwords.escape(dir.path), ApplicationJob.file_pattern)] +
        ApplicationJob.common_subfolders.map do |name, pattern|
          File.join(
            Shellwords.escape(dir.path),
            ApplicationJob.case_insensitive_glob_string(name),
            pattern
          )
        end
      ).uniq.filter { |x| File.file?(x) }
    end
    list
  end

  def perform(model_id)
    model = Model.find(model_id)
    return if model.nil?

    model_path = File.join(model.library.path, model.path)
    return if Problem.create_or_clear(model, :missing, !File.exist?(model_path))
    # For each file in the model, create a file object
    file_list(model_path).each do |filename|
      # Create the file
      file = model.model_files.find_or_create_by(filename: filename.gsub(model_path + "/", ""))
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
  end
end
