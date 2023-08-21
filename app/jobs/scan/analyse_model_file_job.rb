class Scan::AnalyseModelFileJob < ApplicationJob
  queue_as :scan

  def perform(file)
    # Don't run analysis if the file is missing
    # The Problem is raised elsewhere.
    return if !File.exist?(file.pathname)
    # Update stored file metadata if not set
    file.update!(
      digest: file.digest || file.calculate_digest,
      size: file.size || File.size(file.pathname)
    )
    # Detect inefficient file formats
    message = inefficiency_problem(file)
    Problem.create_or_clear(
      file,
      :inefficient,
      !message.nil?,
      note: message
    )
    # Detect duplicates
    Problem.create_or_clear(
      file,
      :duplicate,
      file.duplicate?
    )
  end

  def inefficiency_problem(file)
    return "ASCII STL" if (file.extension === "stl") && (File.read(file.pathname, 6) === "solid ")
    return "Wavefront OBJ" if file.extension === "obj"
    return "ASCII PLY" if (file.extension === "ply") && (File.read(file.pathname, 16) === "ply\rformat ascii")
    nil
  end
end
