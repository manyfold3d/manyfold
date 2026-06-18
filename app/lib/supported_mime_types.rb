module SupportedMimeTypes
  class << self
    prepend MemoWise

    def image_types
      Mime::LOOKUP.filter { |k, v| is_image_mime_type?(v) }.values
    end
    memo_wise :image_types

    def image_extensions
      Mime::EXTENSION_LOOKUP.filter { |k, v| is_image_mime_type?(v) }.keys
    end
    memo_wise :image_extensions

    def video_types
      Mime::LOOKUP.filter { |k, v| is_video_mime_type?(v) }.values
    end
    memo_wise :video_types

    def video_extensions
      Mime::EXTENSION_LOOKUP.filter { |k, v| is_video_mime_type?(v) }.keys
    end
    memo_wise :video_extensions

    def document_types
      Mime::LOOKUP.filter { |k, v| is_document_mime_type?(v) }.values
    end
    memo_wise :document_types

    def document_extensions
      Mime::EXTENSION_LOOKUP.filter { |k, v| is_document_mime_type?(v) }.keys
    end
    memo_wise :document_extensions

    def archive_types
      Mime::LOOKUP.filter { |k, v| is_archive_mime_type?(v) }.values
    end
    memo_wise :archive_types

    def archive_extensions
      Mime::EXTENSION_LOOKUP.filter { |k, v| is_archive_mime_type?(v) }.keys
    end
    memo_wise :archive_extensions

    def model_types
      Mime::LOOKUP.filter { |k, v| is_model_mime_type?(v) }.values
    end
    memo_wise :model_types

    def model_extensions
      Mime::EXTENSION_LOOKUP.filter { |k, v| is_model_mime_type?(v) }.keys
    end
    memo_wise :model_extensions

    def slicer_types
      Mime::LOOKUP.filter { |k, v| is_slicer_mime_type?(v) }.values
    end
    memo_wise :slicer_types

    def slicer_extensions
      Mime::EXTENSION_LOOKUP.filter { |k, v| is_slicer_mime_type?(v) }.keys
    end
    memo_wise :slicer_extensions

    def indexable_types
      image_types + model_types + video_types + document_types + archive_types + slicer_types
    end
    memo_wise :indexable_types

    def indexable_extensions
      image_extensions + model_extensions + video_extensions + document_extensions + archive_extensions + slicer_extensions
    end
    memo_wise :indexable_extensions

    private

    def is_image_mime_type?(type)
      exclusions = [
        "image/vnd.dxf",
        "image/vnd.dwg"
      ]
      type.to_s.start_with?("image/") && exclusions.exclude?(type.to_s)
    end
    memo_wise :is_image_mime_type?

    def is_video_mime_type?(type)
      type.to_s.start_with?("video/")
    end
    memo_wise :is_video_mime_type?

    def is_document_mime_type?(type)
      [
        "application/pdf",
        "text/markdown",
        "text/plain",
        "text/html",
        "text/javascript",
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
    memo_wise :is_document_mime_type?

    def is_model_mime_type?(type)
      extras = [
        "text/x-gcode",
        "application/x-openscad",
        "image/vnd.dxf",
        "image/vnd.dwg",
        "application/x-3ds",
        "application/x-amf",
        "application/x-ldraw",
        "application/vnd.flock+json",
        "application/vnd.dragonfruit.voxl",
        "application/dicom",
        "application/gml+xml",
        "application/vnd.pts",
        "application/vnd.vtk",
        "application/vnd.vtp",
        "application/vnd.off",
        "application/vnd.x",
        "application/vnd.xbf",
        "application/vnd.mdl",
        "application/vnd.ifc",
        "application/vnd.mhd",
        "application/vnd.nrrd",
        "application/vnd.splat",
        "application/vnd.spz"
      ]
      type.to_s.start_with?("model/") || extras.include?(type.to_s)
    end
    memo_wise :is_model_mime_type?

    def is_archive_mime_type?(type)
      [
        "application/zip",
        "application/gzip",
        "application/vnd.rar",
        "application/x-7z-compressed",
        "application/x-bzip2"
      ].include?(type.to_s)
    end
    memo_wise :is_archive_mime_type?

    def is_slicer_mime_type?(type)
      [
        "application/x-chitubox",
        "application/x-prusa-sl1",
        "application/x-phrozen",
        "application/x-photon",
        "application/x-crealitybox",
        "application/x-elegoo",
        "application/x-lumen",
        "application/x-nanodlp"
      ].include?(type.to_s)
    end
    memo_wise :is_slicer_mime_type?
  end
end
