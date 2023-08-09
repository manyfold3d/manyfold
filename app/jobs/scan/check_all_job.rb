class Scan::CheckAllJob < ApplicationJob
  queue_as :scan

  def perform
    # Run integrity check on all models
    Model.all.each do |model|
      Scan::CheckModelIntegrityJob.perform_later(model.id)
      # Run analysis job on individual files
      model.model_files.each do |file|
        Scan::AnalyseModelFileJob.perform_later(file.id)
      end
    end
  end
end
