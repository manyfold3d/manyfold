class PrepareDownloadJob < ApplicationJob
  queue_as :critical
  unique :until_executed

  def perform(model_id:, selection:)
    @model = Model.find(model_id)
    @downloader = ArchiveDownloadService.new(model: @model, selection: selection)
    write_archive(@downloader.temp_file, file_list(@model, selection))
    FileUtils.mv(@downloader.temp_file, @downloader.output_file)
    @model.broadcast_refresh
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
