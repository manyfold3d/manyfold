class ProcessUploadedFileJob < ApplicationJob
  queue_as :default

  def perform(library_id, uploaded_file)
    # Find library
    library = Library.find(library_id)
    return if library.nil?
    # Attach cached upload file
    attacher = Shrine::Attacher.new
    attacher.attach_cached(uploaded_file)
    datafile = attacher.file
    # Create name for temporary destination folder
    dest_folder_name = File.join(library.path, SecureRandom.uuid)
    # Handle different file types
    case File.extname(datafile.original_filename).delete(".").downcase
    when "zip", "rar", "7z", "bz2", "gz"
      unzip(dest_folder_name, datafile)
    else
    end
    # If a folder was created...
    if Dir.exist?(dest_folder_name)
      # Rename destination folder atomically
      file_name = File.basename(datafile.original_filename, File.extname(datafile.original_filename))
      File.rename(dest_folder_name, File.join(library.path, file_name))
      # Queue up model creation for new folder
      Scan::CreateModelJob.perform_later(library.id, file_name, include_all_subfolders: true)
    end
    # Discard cached file
    attacher.destroy
  end

  def unzip(dest_folder_name, datafile)
    datafile.open do |file|
      Archive::Reader.open_fd(file.fileno) do |reader|
        Dir.mkdir(dest_folder_name)
        Dir.chdir(dest_folder_name) do
          reader.each_entry do |entry|
            next if entry.size > SiteSettings.max_file_extract_size
            reader.extract(entry, Archive::EXTRACT_SECURE)
          end
        end
      end
    end

    # Checks the directory just created and if it contains only one directory,
    # moves the contents of that directory up a level, then deletes the empty directory.
    pn = Pathname.new(dest_folder_name)
    if pn.children.length == 1 && pn.children[0].directory?
      dup_dir = Pathname.new(pn.children[0])

      dup_dir.children.each do |child|
        fixed_path = Pathname.new(pn.to_s + "/" + child.basename.to_s)
        File.rename(child.to_s, fixed_path.to_s)
      end

      Dir.delete(dup_dir.to_s)
    end
  end
end
