class ModelFile < ApplicationRecord
  belongs_to :model
  validates :filename, presence: true, uniqueness: {scope: :model}

  default_scope { order(:filename) }

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
  end
end
