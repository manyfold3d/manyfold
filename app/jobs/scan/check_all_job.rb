class Scan::CheckAllJob < ApplicationJob
  queue_as :scan

  def perform
    # Check all models
    Model.find_each do |model|
      Scan::CheckModelJob.perform_later(model.id, scan: false)
    end
  end
end
