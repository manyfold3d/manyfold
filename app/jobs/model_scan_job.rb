class ModelScanJob < ApplicationJob
  queue_as :default

  def clean_up_missing_files(model)
    model.model_files.each do |f|
      if !File.exist?(File.join(model.library.path, model.path, f.filename))
        begin
          f.problems.create(category: :missing)
        rescue
          nil
        end
      else
        f.problems.where(category: :missing).destroy_all
      end
    end
  end

  def perform(model)
    # Clean out missing files
    clean_up_missing_files(model)
    # For each file in the model, create a file object
    model_path = File.join(model.library.path, model.path)
    if !File.exist?(model_path)
      model.problems.create(category: :missing)
      return
    else
      model.problems.where(category: :missing).destroy_all
    end
    Dir.open(model_path) do |dir|
      Dir.glob([
        # File.join(dir.path, ApplicationJob.file_pattern),
        # File.join(dir.path, "files", ApplicationJob.file_pattern),
        # File.join(dir.path, "images", ApplicationJob.image_pattern)
        File.join(dir.path, "*")
      ]).uniq.each do |filename|
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
    # If this model has no files, flag a problem
    if model.model_files.reload.count == 0
      begin
        model.problems.create(category: :empty)
      rescue
        nil
      end
    else
      model.problems.where(category: :empty).destroy_all
    end
  end
end
