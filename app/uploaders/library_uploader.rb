require "shrine/storage/file_system"
require "shrine/storage/s3"
require "shrine/storage/tus"

require "image_processing/mini_magick"

class LibraryUploader < Shrine
  plugin :activerecord
  plugin :add_metadata
  plugin :refresh_metadata
  plugin :metadata_attributes, size: "size"
  plugin :restore_cached_data
  plugin :keep_files
  plugin :determine_mime_type
  plugin :rack_response
  plugin :dynamic_storage
  plugin :tus
  plugin :remote_url, max_size: SiteSettings.max_file_upload_size
  plugin :infer_extension
  plugin :derivatives

  self.storages = {
    cache: Shrine::Storage::FileSystem.new("tmp/shrine"),
    downloads: Shrine::Storage::FileSystem.new("tmp/downloads")
  }

  storage(/library_(\d+)/) do |m|
    Library.find(m[1]).storage # rubocop:disable Pundit/UsePolicyScope
  rescue ActiveRecord::RecordNotFound
    nil
  end

  class Attacher
    def store_key
      @record.model.library.storage_key
    end
  end

  def generate_location(io, record: nil, derivative: nil, metadata: {}, **)
    return super unless record&.valid?
    record.path_within_library(derivative: derivative)
  end

  add_metadata :ctime do |io|
    Shrine.with_file(io) { |it| [it.mtime, it.ctime].compact.min }
  rescue NoMethodError
  end

  add_metadata :mtime do |io|
    Shrine.with_file(io) { |it| it.mtime }
  rescue NoMethodError
  end

  add_metadata :remote_etag do |io|
    io.meta["etag"]
  rescue NoMethodError
  end

  add_metadata :remote_last_modified do |io|
    io.meta["last-modified"]
  rescue NoMethodError
  end

  Attacher.derivatives do |original|
    if context[:record]&.is_image?
      magick = ImageProcessing::MiniMagick.source(original)
      {
        preview: magick.resize_to_limit!(320, 320),
        carousel: magick.resize_to_limit!(1024, 768)
      }
    else
      {}
    end
  end
end
