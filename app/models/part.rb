class Part < ApplicationRecord
  belongs_to :model
  validates :filename, presence: true, uniqueness: {scope: :model}

  def file_format
    File.extname(filename).gsub(".","")
  end

end
