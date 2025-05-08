class ArchiveDownloadService
  attr_reader :pathname

  def initialize(model:, selection:)
    @model = model
    @selection = sanitize selection
    @tmpdir = LibraryUploader.find_storage(:downloads).directory
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
    FileUtils.touch(@tmpfile)
    PrepareDownloadJob.perform_later(
      model_id: @model.id,
      selection: @selection,
      temp_file: @tmpfile,
      output_file: @pathname
    )
  end

  def wait_until_ready
    loop do
      break if ready?
      sleep(1)
    end
  end

  private

  def sanitize(selection)
    selection&.gsub(/\W/, "")
  end
end
