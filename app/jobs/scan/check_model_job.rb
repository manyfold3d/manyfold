class Scan::CheckModelJob < ApplicationJob
  queue_as :scan

  def perform(model_id, scan: true)
    begin
      model = Model.find(model_id)
    rescue ActiveRecord::RecordNotFound
      logger.warn "Scan::CheckModelJob aborted, invalid Model ID #{model_id}"
      return
    end
    if scan
      # Scan for new files (runs integrity check automatically)
      ModelScanJob.perform_later(model.id)
    else
      # Run integrity check
      Scan::CheckModelIntegrityJob.perform_later(model.id)
    end
    # Run analysis job on individual files
    model.model_files.each do |file|
      Analysis::AnalyseModelFileJob.perform_later(file.id)
    end
  end
end
