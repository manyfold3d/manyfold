class ProcessUploadedFileJob < ApplicationJob
  queue_as :default

  def perform(library_id, uploaded_file)
    # Find library
    library = Library.find(library_id)
    return if library.nil?
    # Attach cached upload file
    attacher = Shrine::Attacher.new
    attacher.attach_cached(uploaded_file)
    file = attacher.file
    # Generate model name
    model_path = File.basename(file.original_filename, ".*")
    model_name = model_path.humanize.tr("+", " ").titleize
    # Create model
    model = library.models.create(name: model_name, path: "#{model_path}##{SecureRandom.hex(4)}")
    model.update! path: "#{model_path}##{model.id}" # Set to proper ID after saving
    # Handle different file types
    case File.extname(file.original_filename).delete(".").downcase
    when *SupportedMimeTypes.archive_extensions
      unzip(model, file)
    when *(SupportedMimeTypes.model_extensions + SupportedMimeTypes.image_extensions)
      model.model_files.create(filename: file.original_filename, attachment: file)
    else
      Rails.logger.warn("Ignoring #{file.inspect}")
    end
    # Discard cached file
    attacher.destroy
    # Queue full model scan to fill in data
    ModelScanJob.perform_later(model.id, include_all_subfolders: true)
  end

  private

  def unzip(model, uploaded_file)
    Shrine.with_file(uploaded_file) do |archive|
      Dir.mktmpdir do |tmpdir|
        strip = count_common_path_components(archive)
        Archive::Reader.open_filename(archive.path, strip_components: strip) do |reader|
          reader.each_entry do |entry|
            next if !entry.file? || entry.size > SiteSettings.max_file_extract_size
            Dir.chdir(tmpdir) do
              reader.extract(entry, Archive::EXTRACT_SECURE)
              model.model_files.create(filename: entry.pathname, attachment: File.open(entry.pathname))
            end
          end
        end
      end
    end
  end

  def count_common_path_components(archive)
    # Generate full list of directories in the archive
    paths = []
    Archive::Reader.open_filename(archive.path) do |reader|
      reader.each_entry do |entry|
        paths << entry.pathname if entry.directory?
      end
    end
    paths = paths.map { |path| path.split(File::SEPARATOR) }
    # Count the commont elements in the paths
    count_common_elements(paths)
  end

  def count_common_elements(arrays)
    common = []
    loop do
      elements = arrays.filter_map(&:shift).uniq
      if elements.count == 1
        common << elements[0]
      else
        break
      end
    end
    common.count
  end
end
