class Scan::AnalyseModelFileJob < ApplicationJob
  queue_as :scan

  def perform(file)
    # Update stored file metadata if not set
    file.update!(
      digest: file.digest || file.calculate_digest,
      size: file.size || File.size(file.pathname)
    )
    # Detect inefficient file format
    Problem.create_or_clear(
      file,
      :inefficient,
      (file.extension === "stl") &&
        (File.read(file.pathname, 6) === "solid "),
      note: "ASCII STL"
    )
  end
end
