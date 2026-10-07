# frozen_string_literal: true

class Upgrade::FixNilFileSizeValues < Upgrade::IterationJob
  def build_enumerator(cursor:)
    enumerator_builder.active_record_on_records(ModelFile.unscoped.where(size: nil), cursor: cursor)
  end

  def each_iteration(modelfile)
    modelfile.refresh_metadata!
  rescue Errno::EACCES => ex
    Mosscap.logger.error ex.message
  rescue Shrine::FileNotFound
    Mosscap.logger.error("File not found: #{modelfile.path_within_library}")
  rescue Shrine::Error => ex
    Mosscap.logger.error("File error: #{ex.message} #{modelfile.path_within_library}")
  end
end
