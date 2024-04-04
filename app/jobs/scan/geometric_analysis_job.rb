class Scan::GeometricAnalysisJob < ApplicationJob
  queue_as :analysis

  def perform(file_id)
    # Get model
    file = ModelFile.find(file_id)
    return if file.nil?
    # Get mesh
    mesh = file.mesh
    if mesh
      # Check for manifold mesh
      manifold = true
      mesh.traverse do |object|
        manifold &&= object.manifold?
      end
      Problem.create_or_clear(
        file,
        :non_manifold,
        !manifold
      )
      # If the mesh is manifold, we can check if it's inside out
      solid = true
      mesh.traverse do |object|
        solid &&= object.solid?
      end
      if manifold
        Problem.create_or_clear(
          file,
          :inside_out,
          !solid
        )
      end
    end
  end
end
