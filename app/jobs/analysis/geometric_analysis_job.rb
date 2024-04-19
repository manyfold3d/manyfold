class Analysis::GeometricAnalysisJob < ApplicationJob
  queue_as :analysis

  def perform(file_id)
    # Get model
    file = ModelFile.find(file_id)
    if SiteSettings.analyse_manifold
      # Get mesh
      mesh = begin
        file.mesh
      rescue FloatDomainError
        logger.warn "Analysis::GeometricAnalysisJob aborted: FloatDomainError encountered processing ModelFile ID #{file_id}"
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
      else
        logger.warn "Analysis::GeometricAnalysisJob: couldn't load mesh for ModelFile ID #{file_id}"
      end
    end
  end
end
