class ModelFileScanJob < ApplicationJob
  queue_as :default

  def perform(file)
    # Try to guess if the file is presupported
    if !(
      file.pathname.split(/[[:punct:]]|[[:space:]]/).map(&:downcase) &
      ["presupported", "supported", "sup", "wsupports", "withsupports"]
    ).empty?
      file.update!(presupported: true)
    end
  end
end
