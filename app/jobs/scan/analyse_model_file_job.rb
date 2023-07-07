class Scan::AnalyseModelFileJob < ApplicationJob
  queue_as :scan

  def perform(file)
    # Update stored file metadata if not set
    file.update!(
      digest: file.digest || file.calculate_digest,
      size: file.size || File.size(file.pathname)
    )
  end
end
