# frozen_string_literal: true

class Upgrade::FixNilFileSizeValues
  include Sidekiq::IterableJob

  def on_start
    logger.info { "Job started: #{self.class.name} (Job id: #{jid})" }
  end

  def build_enumerator(*args, cursor:)
    active_record_records_enumerator(ModelFile.where(size: nil), cursor: cursor)
  end

  def each_iteration(modelfile, *args)
    modelfile.update(size: modelfile.attachment_data["metadata"]["size"]) if modelfile.attachment_data?
  end

  def on_complete
    logger.info { "Job completed: #{self.class.name} (Job id: #{jid})" }
  end
end
