require "shrine/storage/file_system"
require "shrine/storage/s3"
require "shrine/storage/tus"

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
    if context[:record]&.try(:is_3d_model?) && FileHandlers::F3dCli.can_load?(context[:record].mime_type)
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
    if (
      (SiteSettings.generate_image_derivatives && context[:record]&.is_image?) ||
      (SiteSettings.generate_model_renders && context[:record]&.is_3d_model?) ||
      (SiteSettings.generate_model_renders && context[:record]&.is_slicer_file?)
    ) && (handler = FileHandlers.handlers_for(environment: :thumbnail, mime_type: context[:record].mime_type).first)
      Shrine.with_file(original) { handler.thumbnailer.new(file: it, record: context[:record]).call }
    else
      {}
    end
  rescue => ex
    Mosscap.logger.warn "Error in derivative generation for #{context[:record].to_param}: #{ex.message}"
    {}
  end
end
