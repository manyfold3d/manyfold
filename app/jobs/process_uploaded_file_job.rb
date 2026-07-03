class ProcessUploadedFileJob < ApplicationJob
  include ArchiveHelpers

  queue_as :critical

  def perform(library_id, uploaded_file, name: nil, owner: nil, creator_id: nil, collection_ids: [], tag_list: nil, license: nil, model: nil, sensitive: nil, permission_preset: nil)
    new_files = []
    new_model = model.nil?
    attachers = []

    ActiveRecord::Base.transaction do
      # Find library
      library = Library.find(library_id)
      return if library.nil?

      attachers = Array.wrap(uploaded_file).map do
        # Attach cached upload file
        attacher = ModelFileUploader::Attacher.new
        attacher.attach_cached(it)
        attacher
      end

      name ||= File.basename(attachers.first.file.original_filename, ".*").humanize.tr("+", " ").careful_titleize
      model ||= create_new_model(library, name: name, owner: owner, creator_id: creator_id, collection_ids: collection_ids, tag_list: tag_list, license: license, sensitive: sensitive, permission_preset: permission_preset)

      attachers.each do
        if new_model && (attachers.length == 1) && is_archive?(it.file)
          # This is a single zipfile going into a new model, so automatically run extract job
          f = add_single_file_to_model(model, it.file)
          ExtractArchiveJob.perform_later(f.id, remove_when_complete: true) if f&.valid?
        else
          new_files << add_single_file_to_model(model, it.file)
        end
      end
    end

    # Queue scans to fill in data or update things
    if new_model
      model.add_new_files_later(include_all_subfolders: true)
    else
      model.check_for_problems_later
    end
    new_files.flatten.each(&:parse_metadata_later)

    attachers.each do
      # Discard cached file
      it.destroy
    end
  end

  def is_archive?(file)
    MediaType.archive_extensions.include? File.extname(file.original_filename).delete(".").downcase
  end

  def create_new_model(library, name: nil, owner: nil, creator_id: nil, collection_ids: [], tag_list: nil, license: nil, sensitive: nil, permission_preset: nil)
    params = {
      name: name,
      path: SecureRandom.uuid,
      creator_id: creator_id,
      collections: collection_ids.map { Collection.find(it) },
      tag_list: tag_list,
      license: license,
      sensitive: sensitive,
      permission_preset: permission_preset,
      owner: owner
    }.compact_blank
    # Create model
    model = library.models.create!(params)
    model.organize!
    model
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

  private

  def unzip_into_model(model, file)
    new_files = []
    ModelFileUploader.with_file(file) do |archive|
      dirname = SecureRandom.uuid
      tmpdir = ModelFileUploader.find_storage(:cache).directory.join(dirname)
      tmpdir.mkdir
      strip = count_common_path_components(archive)
      Archive::Reader.open_filename(archive.path, strip_components: strip) do |reader|
        reader.each_entry do |entry|
          next if !entry.file? || entry.size > SiteSettings.max_file_extract_size
          filename = begin
            entry.pathname.encode(Encoding::UTF_8).scrub
          rescue EncodingError
            entry.pathname.force_encoding(Encoding::UTF_8).scrub
          end
          next if SiteSettings.ignored_file?(filename)
          reader.extract(entry, Archive::EXTRACT_SECURE, destination: tmpdir.to_s)
          new_files << model.model_files.create(filename: filename, attachment: ModelFileUploader.uploaded_file(
            storage: :cache,
            id: File.join(dirname, filename),
            metadata: {filename: File.basename(filename)}
          ))
        end
      end
    end
    new_files
  end
end
