class AddUploadedFileToModelJob < ApplicationJob
  include ArchiveHelpers

  queue_as :critical

  def perform(model_id, tus_upload, auto_extract: false)
    model = Model.find(model_id)

    file = add_single_file_to_model(model, tus_upload)

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

  def add_single_file_to_model(model, tus_upload)
    filename = tus_upload[:name]
    # Handle different file types
    case extension(tus_upload)
    when *MediaType.indexable_extensions
      if (existing_file = model.model_files.where(filename: filename).first)
        existing_file.update(attachment: attachment(tus_upload))
        existing_file
      else
        model.model_files.create(filename: filename, attachment: attachment(tus_upload))
      end
    else
      Rails.logger.warn("Ignoring #{tus_upload.inspect}")
    end
  end

  def attachment(tus_upload)
    {
      id: tus_upload[:id],
      storage: "cache",
      metadata: {
        filename: tus_upload[:name]
      }
    }
  end

  def extension(tus_upload)
    File.extname(tus_upload[:name]).delete(".").downcase
  end
end
