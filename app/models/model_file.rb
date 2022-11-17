class ModelFile < ApplicationRecord
  belongs_to :model
  validates :filename, presence: true, uniqueness: {scope: :model}

  default_scope { order(:filename) }

  after_destroy :remove_file

  def file_format
    File.extname(filename).delete(".").downcase
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

  def missing?
    !File.exist?(pathname)
  end

  private

  def remove_file
    File.delete(pathname) if File.exist?(pathname)
  end
end
