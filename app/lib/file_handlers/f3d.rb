class FileHandlers::F3d < FileHandlers::Base
  class << self
    def scopes
      [:server]
    end

    def input_types
      F3d.reader_mime_types.filter_map { |it| Mime::Type.lookup(it) }.uniq
    end
  end
end
