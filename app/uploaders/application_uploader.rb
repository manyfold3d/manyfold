require "shrine/storage/file_system"
require "shrine/storage/s3"
require "shrine/storage/tus"

require "image_processing/mini_magick"

class ApplicationUploader < Shrine
  plugin :activerecord
  plugin :add_metadata
  plugin :backgrounding
  plugin :refresh_metadata
  plugin :metadata_attributes, size: "size"
  plugin :restore_cached_data
  plugin :keep_files
  plugin :determine_mime_type, analyzer: ->(io, analyzers) do
    (
      Mime::Type.lookup_by_extension(File.extname(io.try(:metadata)&.fetch("filename", "") || "").tr(".", "")&.downcase) ||
      analyzers[:marcel].call(io, filename_fallback: true)
    ).to_s
  end
  plugin :rack_response
  plugin :dynamic_storage
  plugin :tus
  plugin :remote_url, max_size: SiteSettings.max_file_upload_size
  plugin :infer_extension
  plugin :derivatives, create_on_promote: true
  plugin :remove_attachment

  self.storages = {
    cache: Shrine::Storage::FileSystem.new("tmp/shrine"),
    downloads: Shrine::Storage::FileSystem.new("tmp/downloads")
  }

  F3D_OPTS = {
    "ambient-occlusion" => "1",
    "anti-aliasing" => "true",
    "axis" => "0",
    "background-color" => "0,0,0",
    "filename" => "0",
    "grid" => "1",
    "grid-color" => "0,255,255",
    "grid-subdivisions" => 0,
    "grid-unit" => "10",
    "no-config" => "1",
    "output" => "-",
    "resolution" => "512,512",
    "tone-mapping" => "1",
    "translucency-support" => "1"
  }.freeze

  CAMERA_OPTS = {
    "+z" => "-1,1,-0.5",
    "+y" => "-1,-0.5,-1"
  }

  storage(/library_(\d+)/) do |m|
    Library.find(m[1]).storage # rubocop:disable Pundit/UsePolicyScope
  rescue ActiveRecord::RecordNotFound
    nil
  end

  class Attacher
    def store_key
      Library.default.storage_key
    end
  end

  def generate_location(io, record: nil, derivative: nil, metadata: {}, **)
    (storage_key == :cache) ? super : ".manyfold/#{super}"
  end

  add_metadata :ctime do |io|
    Shrine.with_file(io) { [it.mtime, it.ctime].compact.min }
  rescue NoMethodError
  end

  add_metadata :mtime do |io|
    Shrine.with_file(io) { it.mtime }
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

  add_metadata :object do |io, context|
    if context[:record]&.try(:is_3d_model?) && FileHandlers::F3d.can_load?(context[:record].mime_type)
      bounds = Shrine.with_file(io) do |file|
        if file.path
          options = {
            "verbose" => "debug",
            "no-render" => "1",
            "no-config" => "1"
          }
          output, _err = Open3.capture3("f3d", file.path, *options.map { |k, v| "--#{k}=#{v}" })
          output.match(/Scene bounding box: (?<min_x>.*) ≤ x ≤ (?<max_x>.*), (?<min_y>.*) ≤ y ≤ (?<max_y>.*), (?<min_z>.*) ≤ z ≤ (?<max_z>.*)/)
        end
      rescue NoMethodError # To handle failures during tests
      end
      if bounds.nil?
        {}
      else
        {
          "bounding_box" => {
            "minimum" => {
              "x" => bounds[:min_x].to_f,
              "y" => bounds[:min_y].to_f,
              "z" => bounds[:min_z].to_f
            },
            "maximum" => {
              "x" => bounds[:max_x].to_f,
              "y" => bounds[:max_y].to_f,
              "z" => bounds[:max_z].to_f
            }
          }
        }
      end
    end
  end

  Attacher.derivatives do |original|
    if SiteSettings.generate_image_derivatives && context[:record]&.is_image?
      Shrine.with_file(original) do
        magick = ImageProcessing::MiniMagick.source(it)
        {
          preview: magick.resize_to_limit!(320, 320),
          carousel: magick.resize_to_limit!(1024, 768)
        }
      end
    elsif SiteSettings.generate_model_renders && FileHandlers::GcodeThumbnailExtractor.can_load?(context[:record].mime_type)
      Shrine.with_file(original) do
        {render: GcodeThumbnailExtractorService.new(file: it).call}.compact
      end
    elsif SiteSettings.generate_model_renders && FileHandlers::FreecadThumbnailExtractor.can_load?(context[:record].mime_type)
      Shrine.with_file(original) do
        {render: FreecadThumbnailExtractorService.new(file: it).call}.compact
      end
    elsif SiteSettings.generate_model_renders && FileHandlers::F3d.can_load?(context[:record].mime_type) && context[:record]&.is_3d_model?
      Shrine.with_file(original) do
        up = context[:record]&.up_direction
        options = F3D_OPTS.merge(
          "up" => up,
          "camera-direction" => CAMERA_OPTS[up]
        )
        options["color"] = "1,1,1" if context[:record].mime_type.to_s == "model/obj"
        if (plane = context[:record]&.planar?)
          options["grid"] = "0"
          options["up"] = {
            x: "-x",
            y: "-y",
            z: "-z"
          }[plane]
          options["camera-direction"] = {
            x: "0,0,-1",
            y: "-1,0,0",
            z: "0,-1,0"
          }[plane]
        end
        output, _err = Open3.capture3("f3d", it.path, *options.map { |k, v| "--#{k}=#{v}" })
        {
          render: (output.length > 0) ? StringIO.new(output) : nil
        }.compact
      end
    else
      {}
    end
  rescue => ex
    Rails.logger.warn "Error in derivative generation for #{context[:record].to_param}: #{ex.message}"
    {}
  end
end
