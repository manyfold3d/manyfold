class ModelFileUploader < ApplicationUploader
  class Attacher
    def store_key
      @record.model.library.storage_key
    end
  end

  Attacher.promote_block do
    FilePromoteJob.perform_later(self.class.name, record.class.name, record.id, name.to_s, file_data)
  end
  Attacher.destroy_block do
    FileDestroyJob.perform_later(self.class.name, data)
  end

  def generate_location(io, record: nil, derivative: nil, metadata: {}, **)
    return super unless record&.valid?
    record.path_within_library(derivative: derivative)
  end
end
