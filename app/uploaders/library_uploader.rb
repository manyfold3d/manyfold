require "shrine/storage/file_system"
require "shrine/storage/s3"
require "shrine/storage/tus"

class LibraryUploader < Shrine
  plugin :activerecord
  plugin :refresh_metadata
  plugin :determine_mime_type
  plugin :rack_response
  plugin :dynamic_storage
  plugin :tus

  self.storages = {
    cache: Shrine::Storage::FileSystem.new("tmp/shrine")
  }

  storage(/library_(\d+)/) do |m|
    Library.find(m[1]).storage
  end

  class Attacher
    def store_key
      @record.model.library.storage_key
    end
  end

  def generate_location(io, record: nil, derivative: nil, metadata: {}, **)
    return super unless record&.valid?
    record.path_within_library
  end
end
