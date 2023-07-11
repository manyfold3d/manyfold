class Scan::CheckAllJob < ApplicationJob
  queue_as :scan

  def perform
    # Run integrity check on all models
    Model.all.each do |model|
      Scan::CheckModelIntegrityJob.perform_later(model)
      # Run analysis job on individual files
      model.model_files.each do |file|
        Scan::AnalyseModelFileJob.perform_later(file)
      end
    end
  end
end
