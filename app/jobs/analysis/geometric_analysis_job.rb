class Analysis::GeometricAnalysisJob < ApplicationJob
  queue_as :analysis

  def perform(file_id)
    # Get model
    file = ModelFile.find(file_id)
    return if file.nil?
    # Get mesh
    mesh = file.mesh
    if mesh
      # Check for manifold mesh
      manifold = mesh.manifold?
      Problem.create_or_clear(
        file,
        :non_manifold,
        !manifold
      )
      # Temporarily disabled for release
      # # If the mesh is manifold, we can check if it's inside out
      # if manifold
      #   Problem.create_or_clear(
      #     file,
      #     :inside_out,
      #     !mesh.solid?
      #   )
      # end
    end
  end
end
