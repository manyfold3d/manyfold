class ProcessUploadedFileJob < ApplicationJob
  queue_as :default

  def perform(library_id, uploaded_file, owner: nil, creator_id: nil, collection_id: nil, tags: nil, license: nil, model: nil)
    # Find library
    library = Library.find(library_id)
    return if library.nil?
    # Attach cached upload file
    attacher = LibraryUploader::Attacher.new
    attacher.attach_cached(uploaded_file)
    file = attacher.file
    data = {
      name: File.basename(file.original_filename, ".*").humanize.tr("+", " ").careful_titleize,
      path: SecureRandom.uuid,
      creator_id: creator_id,
      collection_id: collection_id,
      tag_list: tags,
      license: license
    }.compact
    # Create model
    new_model = false
    new_file = nil
    ActiveRecord::Base.transaction do
      if model.nil?
        data.merge!(Model.caber_owner(owner)) if owner
        model = library.models.create!(data)
        model.organize!
        new_model = true
      end
      # Handle different file types
      case File.extname(file.original_filename).delete(".").downcase
      when *SupportedMimeTypes.archive_extensions
        unzip(model, file)
      when *SupportedMimeTypes.indexable_extensions
        new_file = model.model_files.create(filename: file.original_filename, attachment: file)
      else
        Rails.logger.warn("Ignoring #{file.inspect}")
      end
    end
    # Discard cached file
    attacher.destroy
    # Queue scans to fill in data or update things
    if new_model
      ModelScanJob.perform_later(model.id, include_all_subfolders: true)
    else
      Scan::CheckModelIntegrityJob.perform_later(model.id)
    end
    ModelFileScanJob.perform_later(new_file.id) if new_file
  end

  private

  def unzip(model, uploaded_file)
    LibraryUploader.with_file(uploaded_file) do |archive|
      tmpdir = LibraryUploader.find_storage(:cache).directory.join(SecureRandom.uuid)
      tmpdir.mkdir
      strip = count_common_path_components(archive)
      Archive::Reader.open_filename(archive.path, strip_components: strip) do |reader|
        reader.each_entry do |entry|
          next if !entry.file? || entry.size > SiteSettings.max_file_extract_size
          next if SiteSettings.ignored_file?(entry.pathname)
          filename = entry.pathname # Stored because pathname gets mutated by the extract and we want the original
          reader.extract(entry, Archive::EXTRACT_SECURE, destination: tmpdir.to_s)
          model.model_files.create(filename: filename, attachment: File.open(entry.pathname))
          # Clean up file
          File.delete(entry.pathname) if File.exist?(entry.pathname)
        end
      end
      # Clean up temp folder
      Dir.rmdir(tmpdir) if Dir.empty?(tmpdir)
    end
  end

  def count_common_path_components(archive)
    # Generate full list of directories in the archive
    paths = []
    files_in_root = false
    Archive::Reader.open_filename(archive.path) do |reader|
      reader.each_entry do |entry|
        paths << entry.pathname if entry.directory?
        files_in_root = true if entry.file? && entry.pathname.exclude?(File::SEPARATOR)
      end
    end
    return 0 if files_in_root
    paths = paths.map { |path| path.split(File::SEPARATOR) }
    # Count the common elements in the paths
    count_common_elements(paths)
  end

  def count_common_elements(arrays)
    return 0 if arrays.empty?
    first = arrays.shift
    zip = first.zip(*arrays)
    zip.count { |x| x.uniq.count == 1 }
  end
end
