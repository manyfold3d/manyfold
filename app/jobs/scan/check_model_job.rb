class Scan::CheckModelJob < ApplicationJob
  queue_as :scan
  unique :until_executed

  def perform(model_id, scan: true)
    model = Model.find(model_id)
    if scan
      # Scan for new files (runs integrity check automatically)
      ModelScanJob.perform_later(model.id)
    else
      # Run integrity check
      model.check_integrity_later
    end
    # Run analysis job on individual files
    model.model_files.each do |file|
      Analysis::AnalyseModelFileJob.perform_later(file.id)
    end
  end
end
