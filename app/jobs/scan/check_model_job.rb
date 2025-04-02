class Scan::CheckModelJob < ApplicationJob
  queue_as :scan
  unique :until_executed

  def perform(model_id, scan: true)
    model = Model.find(model_id)
    if scan
      # Scan for new files (runs integrity check automatically)
      model.scan_later
    else
      # Run integrity check
      model.check_for_problems_later
    end
    # Run analysis job on individual files
    model.model_files.each do |file|
      file.analyse_later
    end
  end
end
