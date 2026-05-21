class MeshLoadError < StandardError
end

class Analysis::GeometricAnalysisJob < ApplicationJob
  queue_as :performance
  sidekiq_options retry: false
  unique :until_executed

  def perform(file_id)
    # Get model
    file = ModelFile.find(file_id)
    return unless file.loadable?
    if SiteSettings.analyse_manifold
      status[:step] = "jobs.analysis.geometric_analysis.loading_mesh" # i18n-tasks-use t('jobs.analysis.geometric_analysis.loading_mesh')
      # Get mesh
      scene = file.scene
      if scene
        status[:step] = "jobs.analysis.geometric_analysis.manifold_check" # i18n-tasks-use t('jobs.analysis.geometric_analysis.manifold_check')
        # Check that all meshes are manifold
        manifold = scene.meshes.map { manifold?(it) }.all?
        Problem.create_or_clear(
          file,
          :non_manifold,
          !manifold
        )
        # Temporarily disabled for release
        # # If the mesh is manifold, we can check if it's inside out
        # if manifold
        # i18n-tasks-use t('jobs.analysis.geometric_analysis.direction_check')
        # status[:step] = "jobs.analysis.geometric_analysis.direction_check"
        #   Problem.create_or_clear(
        #     file,
        #     :inside_out,
        #     !mesh.solid?
        #   )
        # end
      else
        raise MeshLoadError.new
      end
    end
  end

  private

  def manifold?(mesh)
    # Shortcut if there is nothing here
    return true if mesh.num_faces == 0
    # Detect manifold geometry in this object
    edges = {}
    # For each face, record its edges in the edge hash
    mesh.faces.each do |face|
      update_edge_hash face.indices[0], face.indices[1], edges
      update_edge_hash face.indices[1], face.indices[2], edges
      update_edge_hash face.indices[2], face.indices[0], edges
    end
    # If there's anything left in the edge hash, then either
    # we have holes, or we have badly oriented faces
    edges.empty?
  end

  # Updates edge hash with the passed vertex indexes
  # First, the reverse edge is searched for in the hash
  # If found, it's removed as we've got a match
  # If not, we record this edge in the hash
  def update_edge_hash(v1, v2, edges)
    return if edges.delete [v2, v1].pack("QQ")
    edges[[v1, v2].pack("QQ")] = true
  end
end
