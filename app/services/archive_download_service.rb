class ArchiveDownloadService
  def initialize(model:, selection:)
    @model = model
    @selection = sanitize selection
  end

  def filename
    @filename ||= [
      sanitize(@model.slug),
      @selection
    ].compact.join("-") + ".zip"
  end

  def output_file
    @output_file ||= File.join(
      ModelFileUploader.find_storage(:downloads).directory,
      filename
    )
  end

  def temp_file
    @temp_file ||= File.join(
      ModelFileUploader.find_storage(:downloads).directory,
      Digest::SHA256.hexdigest(filename)
    )
  end

  def ready?
    File.exist?(output_file)
  end

  def preparing?
    File.exist?(temp_file)
  end

  def prepare(delay: 0.seconds, queue: nil)
    return if ready? || preparing?
    FileUtils.touch(temp_file)
    PrepareDownloadJob.set(wait: delay, queue: queue).perform_later(
      model_id: @model.id,
      selection: @selection
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
