require "shrine/storage/file_system"
require "shrine/storage/s3"
require "shrine/storage/tus"

require "image_processing/mini_magick"

class ApplicationUploader < Shrine
  plugin :activerecord
  plugin :add_metadata
  plugin :refresh_metadata
  plugin :metadata_attributes, size: "size", digest: "digest"
  plugin :restore_cached_data
  plugin :keep_files
  plugin :determine_mime_type
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
    ".manyfold/#{super}"
  end

  add_metadata :digest do |io|
    updated = false
    sha = Digest::SHA512.new
    while (chunk = io.read(8192))
      updated = true
      sha.update(chunk)
    end
    sha.hexdigest if updated
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

  add_metadata :object do |io|
    Shrine.with_file(io) do |it|
      scene = Assimp.import_file(it.path)
      scene.apply_post_processing(
        0x80000000 # GenBoundingBox step, currently missing from assimp-ffi
      )
      bboxes = scene.meshes.map(&:aabb)
      {
        "bounding_box" => {
          "minimum" => {
            "x" => bboxes.map { |it| it.min.x }.min,
            "y" => bboxes.map { |it| it.min.y }.min,
            "z" => bboxes.map { |it| it.min.z }.min
          },
          "maximum" => {
            "x" => bboxes.map { |it| it.max.x }.max,
            "y" => bboxes.map { |it| it.max.y }.max,
            "z" => bboxes.map { |it| it.max.z }.max
          }
        }
      }
    rescue => ex
      # Assimp doesn't raise a specific error for failed load,
      # just throws a string, so we have to catch all and absorb
      Rails.logger.debug { "Load error: '#{ex.message}'" }
      nil
    end
  end

  Attacher.derivatives do |original|
    if SiteSettings.generate_image_derivatives
      if context[:record]&.is_image?
        Shrine.with_file(original) do |it|
          magick = ImageProcessing::MiniMagick.source(it)
          {
            preview: magick.resize_to_limit!(320, 320),
            carousel: magick.resize_to_limit!(1024, 768)
          }
        end
      else
        {}
      end
    else
      {}
    end
  end
end
