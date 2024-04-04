class ModelFile < ApplicationRecord
  extend Memoist

  belongs_to :model
  has_many :problems, as: :problematic, dependent: :destroy

  belongs_to :presupported_version, class_name: "ModelFile", optional: true
  has_one :unsupported_version, class_name: "ModelFile", foreign_key: "presupported_version_id",
    inverse_of: :presupported_version, dependent: :nullify

  validates :filename, presence: true, uniqueness: {scope: :model}
  validate :presupported_version_is_presupported
  validate :presupported_files_cannot_have_presupported_version

  default_scope { order(:filename) }
  scope :unsupported, -> { where(presupported: false) }
  scope :presupported, -> { where(presupported: true) }

  acts_as_favoritable

  SUPPORT_KEYWORDS = %w[
    presupported
    presup
    supported
    sup
    wsupports
    withsupports
  ]

  def extension
    File.extname(filename).delete(".").downcase
  end

  def is_image?
    SupportedMimeTypes.image_extensions.include? extension
  end

  def is_3d_model?
    SupportedMimeTypes.model_extensions.include? extension
  end

  def mime_type
    Mime::Type.lookup_by_extension(extension)
  end

  def name
    File.basename(filename, ".*").humanize.titleize
  end

  def pathname
    File.join(model.library.path, model.path, filename)
  end

  def calculate_digest
    Digest::SHA512.new.file(pathname).hexdigest
  rescue Errno::ENOENT
    nil
  end

  def bounding_box
    return nil unless mesh
    bbox = Mittsu::Box3.new.set_from_object(mesh)
    bbox.size.to_a
  end

  def duplicates
    return ModelFile.none if digest.nil?
    ModelFile.where(digest: digest).where.not(id: id)
  end

  def duplicate?
    duplicates.count > 0
  end

  # Used for ETag in conditional GETs
  # See https://guides.rubyonrails.org/caching_with_rails.html#conditional-get-support
  def cache_key_with_version
    digest
  end

  def delete_from_disk_and_destroy
    # Delete actual file
    FileUtils.rm(pathname) if File.exist?(pathname)
    # Rescan any duplicates
    duplicates.each { |x| Scan::AnalyseModelFileJob.perform_later(x.id) }
    # Remove the db record
    destroy
  end

  def set_printed_by_user(user, printed)
    if printed
      user.favorite(self, scope: :printed)
    else
      user.unfavorite(self, scope: :printed)
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    ["caption", "created_at", "digest", "filename", "id", "notes", "presupported", "size", "updated_at", "y_up", "presupported_version_id", "unsupported_version_id"]
  end

  def self.ransackable_associations(_auth_object = nil)
    ["favorited", "model", "problems"]
  end

  def mesh
    loader&.new&.load(pathname)
  end
  memoize :mesh

  private

  def presupported_files_cannot_have_presupported_version
    if presupported_version && presupported
      errors.add(:presupported_version, :already_presupported)
    end
  end

  def presupported_version_is_presupported
    if presupported_version && !presupported_version.presupported
      errors.add(:presupported_version, :not_supported)
    end
  end

  def loader
    case extension
    when "stl"
      Mittsu::STLLoader
    when "obj"
      Mittsu::OBJLoader
    end
  end
end
