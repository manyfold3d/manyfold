class ModelScanJob < ApplicationJob
  queue_as :default

  def perform(model)
    # For each file in the model, create a file object
    model_path = File.join(model.library.path, model.path)
    return if Problem.create_or_clear(model, :missing, !File.exist?(model_path))
    Dir.open(model_path) do |dir|
      Dir.glob([
        File.join(dir.path, ApplicationJob.file_pattern),
        File.join(dir.path, "files", ApplicationJob.file_pattern),
        File.join(dir.path, "images", ApplicationJob.image_pattern),
        File.join(dir.path, "presupported", ApplicationJob.file_pattern),
        File.join(dir.path, "unsupported", ApplicationJob.file_pattern),
        File.join(dir.path, "parts", ApplicationJob.file_pattern),
        File.join(dir.path, "supported", ApplicationJob.file_pattern)
      ]).uniq.filter { |x| File.file?(x) }.each do |filename|
        # Create the file
        file = model.model_files.find_or_create_by(filename: filename.gsub(model_path + "/", ""))
        ModelFileScanJob.perform_later(file) if file.valid?
      end
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
