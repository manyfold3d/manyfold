class Scan::CheckModelJob < ApplicationJob
  queue_as :scan
  unique :until_executed

  def perform(model_id)
    model = Model.find(model_id)
    # Scan for new files (runs integrity check automatically)
    model.add_new_files_later
    # Rerun analysis job on individual files
    model.model_files.without_special.each do |file|
      file.analyse_later
    end
  end
end
