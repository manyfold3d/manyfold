class AddUploadedFileToModelJob < ApplicationJob
  include ArchiveHelpers

  queue_as :critical

  def perform(model_id, uploaded_file, auto_extract: false)
    model = Model.find(model_id)

    file = add_single_file_to_model(model, uploaded_file)

    if file&.valid?
      if auto_extract && file.is_archive?
        # Automatically run extract job
        ExtractArchiveJob.perform_later(file.id, remove_when_complete: true)
      else
        file.parse_metadata_later
      end
    end

    model.check_for_problems_later
  end

  def add_single_file_to_model(model, file)
    # Handle different file types
    case File.extname(file.original_filename).delete(".").downcase
    when *MediaType.indexable_extensions
      if (existing_file = model.model_files.where(filename: file.original_filename).first)
        existing_file.update(attachment: file)
        existing_file
      else
        model.model_files.create(filename: file.original_filename, attachment: file)
      end
    else
      Rails.logger.warn("Ignoring #{file.inspect}")
    end
  end
end
