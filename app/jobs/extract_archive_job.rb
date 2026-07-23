class ExtractArchiveJob < ApplicationJob
  include ArchiveHelpers

  queue_as :default

  def perform(file_id, remove_when_complete: false)
    file = ModelFile.find(file_id)
    return unless file.is_archive?

    unzip_into_model(file)

    if remove_when_complete
      file.destroy
    end
  end

  private

  def unzip_into_model(file)
    ModelFileUploader.with_file(file.attachment.open) do |archive|
      strip = count_common_path_components(archive)
      Archive::Reader.open_filename(archive.path, strip_components: strip) do |reader|
        reader.each_entry do |entry|
          extract_entry_to_model_file(reader, entry, file.model)
        end
      end
    end
  end

  def extract_entry_to_model_file(reader, entry, model)
    return if !entry.file? || entry.size > SiteSettings.max_file_extract_size

    filename = begin
      entry.pathname.encode(Encoding::UTF_8).scrub
    rescue EncodingError
      entry.pathname.force_encoding(Encoding::UTF_8).scrub
    end
    return if SiteSettings.ignored_file?(filename)

    # Find if file exists already
    if (existing_file = model.model_files.find_by(filename: filename))
      # If the existing file is not the same as the one in the archive, overwrite it
      if existing_file.size != entry.size
        reader.extract(entry, Archive::EXTRACT_SECURE_WITH_OVERWRITE, destination: File.join(model.library.path, model.path))
        existing_file.refresh_metadata!
      end
    else
      reader.extract(entry, Archive::EXTRACT_SECURE, destination: File.join(model.library.path, model.path))
      new_file = ApplicationRecord.suppressing_turbo_broadcasts { model.model_files.find_or_create_by(filename: filename) }
      new_file.parse_metadata_later
    end
  end
end
