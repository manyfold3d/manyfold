class ModelFile < ApplicationRecord
  belongs_to :model
  has_many :problems, as: :problematic, dependent: :destroy

  validates :filename, presence: true, uniqueness: {scope: :model}

  default_scope { order(:filename) }

  def extension
    File.extname(filename).delete(".").downcase
  end

  def is_image?
    SupportedMimeTypes.image_extensions.include? extension
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

  def remove_file
    File.delete(pathname) if File.exist?(pathname)
  end
end
