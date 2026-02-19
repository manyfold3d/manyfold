# frozen_string_literal: true

class Upgrade::FixNilFileSizeValues < ApplicationJob
  include JobIteration::Iteration

  unique :until_executed

  def build_enumerator(cursor:)
    enumerator_builder.active_record_on_records(ModelFile.unscoped.where(size: nil), cursor: cursor)
  end

  def each_iteration(modelfile)
    ApplicationRecord.no_touching do
      modelfile.attachment_attacher.refresh_metadata!
      modelfile.save(touch: false, validate: false)
    end
  rescue Errno::EACCES => ex
    Rails.logger.error ex.message
  rescue Shrine::FileNotFound
    Rails.logger.error("File not found: #{modelfile.path_within_library}")
  rescue Shrine::Error => ex
    Rails.logger.error("File error: #{ex.message} #{modelfile.path_within_library}")
  end
end
