class LibraryUploader < Shrine
  plugin :dynamic_storage

  storage(/library_(\d)/) do |m|
    Library.find(m[1]).storage
  end

  class Attacher
    def store_key
      @record.model.library.storage_key
    end
  end

  def generate_location(io, record: nil, derivative: nil, metadata: {}, **)
    return super unless record
    record.path_within_library
  end
end
