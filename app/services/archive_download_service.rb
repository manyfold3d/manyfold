class ArchiveDownloadService
  attr_reader :pathname

  def initialize(model:, selection:)
    @model = model
    @selection = selection
    @tmpdir = LibraryUploader.find_storage(:cache).directory
    @pathname = File.join(@tmpdir, "#{@model.updated_at.to_time.to_i}-#{@model.id}-#{@selection}.zip")
    @tmpfile = File.join(@tmpdir, Digest::SHA256.hexdigest(@pathname))
  end

  def filename
    [
      @model.slug,
      @selection
    ].compact.join("-") + ".zip"
  end

  def ready?
    File.exist?(@pathname)
  end

  def preparing?
    File.exist?(@tmpfile)
  end

  def prepare
    return if ready? || preparing?

    tmpfile = File.join(@tmpdir, "#{SecureRandom.urlsafe_base64}.zip")
    write_archive(tmpfile, file_list(@model, @selection))
    FileUtils.mv(tmpfile, @pathname)
  end

  def wait_until_ready
    loop do
      break if ready?
      sleep(1)
    end
  end

  private

  def file_list(model, selection)
    scope = model.model_files
    case selection
    when nil
      scope
    when "supported"
      scope.where(presupported: true)
    when "unsupported"
      scope.where(presupported: false)
    else
      scope.select { |f| f.extension == selection }
    end
  end

  def write_archive(filename, files)
    Archive.write_open_filename(filename, Archive::COMPRESSION_COMPRESS, Archive::FORMAT_ZIP) do |archive|
      files.each do |file|
        archive.new_entry do |entry|
          entry.pathname = file.filename
          entry.size = file.size
          entry.filetype = Archive::Entry::FILE
          entry.mtime = file.mtime
          entry.ctime = file.ctime
          archive.write_header entry
          archive.write_data file.attachment.read
        end
      end
    end
  end
end
