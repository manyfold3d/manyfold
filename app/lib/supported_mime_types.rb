module SupportedMimeTypes
  class << self
    extend Memoist

    def image_types
      Mime::LOOKUP.filter { |k, v| is_image_mime_type?(v) }.values
    end
    memoize :image_types

    def image_extensions
      Mime::EXTENSION_LOOKUP.filter { |k, v| is_image_mime_type?(v) }.keys
    end
    memoize :image_extensions

    def video_types
      Mime::LOOKUP.filter { |k, v| is_video_mime_type?(v) }.values
    end
    memoize :video_types

    def video_extensions
      Mime::EXTENSION_LOOKUP.filter { |k, v| is_video_mime_type?(v) }.keys
    end
    memoize :video_extensions

    def document_types
      Mime::LOOKUP.filter { |k, v| is_document_mime_type?(v) }.values
    end
    memoize :document_types

    def document_extensions
      Mime::EXTENSION_LOOKUP.filter { |k, v| is_document_mime_type?(v) }.keys
    end
    memoize :document_extensions

    def archive_types
      Mime::LOOKUP.filter { |k, v| is_archive_mime_type?(v) }.values
    end
    memoize :archive_types

    def archive_extensions
      Mime::EXTENSION_LOOKUP.filter { |k, v| is_archive_mime_type?(v) }.keys
    end
    memoize :archive_extensions

    def model_types
      Mime::LOOKUP.filter { |k, v| is_model_mime_type?(v) }.values
    end
    memoize :model_types

    def model_extensions
      Mime::EXTENSION_LOOKUP.filter { |k, v| is_model_mime_type?(v) }.keys
    end
    memoize :model_extensions

    def loadable
      Mime::EXTENSION_LOOKUP.slice(
        *Assimp.extension_list.to_s.delete("*.").split(";")
      ).values.map(&:to_sym)
    end
    memoize :loadable

    def can_load?(type)
      loadable.include? type
    end
    memoize :can_load?

    def exportable
      Mime::EXTENSION_LOOKUP.slice(
        *(0...Assimp.aiGetExportFormatCount).map { |it| Assimp.aiGetExportFormatDescription it }.map(&:file_extension)
      ).values.map(&:to_sym)
    end
    memoize :exportable

    def can_export?(type)
      exportable.include? type
    end
    memoize :can_export?

    def renderable_types
      readers = `f3d --list-readers`.lines
      types = readers.filter_map { |it| it.match(/\w[a-z]*\/[0-9a-z.+-]*\w/)&.to_s }
      types.filter_map { |it| Mime::Type.lookup(it) }.uniq
    end
    memoize :renderable_types

    def can_render?(type)
      renderable_types.include? type
    end
    memoize :can_render?

    def indexable_types
      image_types + model_types + video_types + document_types + archive_types
    end
    memoize :indexable_types

    def indexable_extensions
      image_extensions + model_extensions + video_extensions + document_extensions + archive_extensions
    end
    memoize :indexable_extensions

    private

    def is_image_mime_type?(type)
      exclusions = [
        "image/vnd.dxf",
        "image/vnd.dwg"
      ]
      type.to_s.start_with?("image/") && exclusions.exclude?(type.to_s)
    end
    memoize :is_image_mime_type?

    def is_video_mime_type?(type)
      type.to_s.start_with?("video/")
    end
    memoize :is_video_mime_type?

    def is_document_mime_type?(type)
      [
        "application/pdf",
        "text/markdown",
        "text/plain",
        "text/html",
        "application/msword",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "application/octet-stream",
        "application/x-gerber",
        "application/x-gerber-job",
        "application/x-excellon",
        "application/x-kicad-project",
        "application/x-kicad-footprint",
        "application/x-kicad-pcb",
        "application/x-kicad-symbol",
        "application/x-kicad-schematic",
        "application/x-kicad-worksheet"
      ].include?(type.to_s)
    end
    memoize :is_document_mime_type?

    def is_model_mime_type?(type)
      extras = [
        "text/x-gcode",
        "application/x-openscad",
        "image/vnd.dxf",
        "image/vnd.dwg",
        "application/x-3ds",
        "application/x-amf",
        "application/x-ldraw",
        "application/vnd.flock+json"
      ]
      type.to_s.start_with?("model/") || extras.include?(type.to_s)
    end
    memoize :is_model_mime_type?

    def is_archive_mime_type?(type)
      [
        "application/zip",
        "application/gzip",
        "application/vnd.rar",
        "application/x-7z-compressed",
        "application/x-bzip2"
      ].include?(type.to_s)
    end
    memoize :is_archive_mime_type?
  end
end
