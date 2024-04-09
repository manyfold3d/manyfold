class Scan::CheckModelJob < ApplicationJob
  queue_as :scan

  def perform(model_id, scan: true)
    begin
      model = Model.find(model_id)
    rescue ActiveRecord::RecordNotFound
      return
    end
    # Scan for new files
    ModelScanJob.perform_later(model.id) if scan
    # Run integrity check
    Scan::CheckModelIntegrityJob.perform_later(model.id)
    # Run analysis job on individual files
    model.model_files.each do |file|
      Analysis::AnalyseModelFileJob.perform_later(file.id)
    end
  end
end
