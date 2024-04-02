class Scan::GeometricAnalysisJob < ApplicationJob
  queue_as :scan

  def perform(file_id)
  end
end
