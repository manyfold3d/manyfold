class ModelFileScanJob < ApplicationJob
  queue_as :default

  def perform(file)
    # Try to guess if the file is presupported
    model_path = File.join(file.model.library.path, file.model.path)
    if !(
      File.join(model_path, file.filename).split(/[[:punct:]]|[[:space:]]/).map(&:downcase) &
      ["presupported", "supported", "sup", "wsupports", "withsupports"]
    ).empty?
      file.update!(presupported: true)
    end
  end
end
