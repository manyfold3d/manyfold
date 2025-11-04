class ProcessUploadedFileJob < ApplicationJob
  queue_as :critical

  def perform(library_id, uploaded_file, name: nil, owner: nil, creator_id: nil, collection_id: nil, tag_list: nil, license: nil, model: nil, sensitive: nil, permission_preset: nil)
    ActiveRecord::Base.transaction do
      # Find library
      library = Library.find(library_id)
      return if library.nil?
      new_model = model.nil?

      attachers = Array.wrap(uploaded_file).map do |it|
        # Attach cached upload file
        attacher = ModelFileUploader::Attacher.new
        attacher.attach_cached(it)
        attacher
      end

      name ||= File.basename(attachers.first.file.original_filename, ".*").humanize.tr("+", " ").careful_titleize
      model ||= create_new_model(library, name: name, owner: owner, creator_id: creator_id, collection_id: collection_id, tag_list: tag_list, license: license, sensitive: sensitive, permission_preset: permission_preset)

      new_files = []
      attachers.each do |it|
        new_files << if new_model && (attachers.length == 1) && is_archive?(it.file)
          unzip_into_model(model, it.file)
        else
          add_single_file_to_model(model, it.file)
        end
      end

      # Queue scans to fill in data or update things
      if new_model
        model.add_new_files_later(include_all_subfolders: true)
      else
        model.check_for_problems_later
      end
      new_files.flatten.each(&:parse_metadata_later)

      attachers.each do |it|
        # Discard cached file
        it.destroy
      end
    end
  end

  def is_archive?(file)
    SupportedMimeTypes.archive_extensions.include? File.extname(file.original_filename).delete(".").downcase
  end

  def create_new_model(library, name: nil, owner: nil, creator_id: nil, collection_id: nil, tag_list: nil, license: nil, sensitive: nil, permission_preset: nil)
    params = {
      name: name,
      path: SecureRandom.uuid,
      creator_id: creator_id,
      collection_id: collection_id,
      tag_list: tag_list,
      license: license,
      sensitive: sensitive,
      permission_preset: permission_preset,
      owner: owner
    }.compact
    # Create model
    model = library.models.create!(params)
    model.organize!
    model
  end

  def add_single_file_to_model(model, file)
    # Handle different file types
    case File.extname(file.original_filename).delete(".").downcase
    when *SupportedMimeTypes.indexable_extensions
      new_file = model.model_files.create(filename: file.original_filename, attachment: file)
    else
      Rails.logger.warn("Ignoring #{file.inspect}")
    end
    new_file
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
          next if SiteSettings.ignored_file?(entry.pathname)
          filename = entry.pathname # Stored because pathname gets mutated by the extract and we want the original
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
    zip.count { |it| it.uniq.count == 1 }
  end
end
