class Analysis::GeometricAnalysisJob < ApplicationJob
  queue_as :analysis

  def perform(file_id)
    # Get model
    begin
      file = ModelFile.find(file_id)
    rescue ActiveRecord::RecordNotFound
      return
    end
    if SiteSettings.analyse_manifold
      # Get mesh
      mesh = begin
        file.mesh
      rescue FloatDomainError
        nil
      end
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
end
