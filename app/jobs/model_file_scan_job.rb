class ModelFileScanJob < ApplicationJob
  queue_as :default

  def perform(file_id)
    begin
      file = ModelFile.find(file_id)
    rescue ActiveRecord::RecordNotFound
      logger.warn "ModelFileScanJob aborted, invalid ModelFile ID #{file_id}"
      return
    end
    # Try to guess if the file is presupported
    if !(
      file.pathname.split(/[[:punct:]]|[[:space:]]/).map(&:downcase) & ModelFile::SUPPORT_KEYWORDS
    ).empty?
      file.update!(presupported: true)
    end
    # Queue up deeper analysis job
    Analysis::AnalyseModelFileJob.perform_later(file.id)
  end
end
