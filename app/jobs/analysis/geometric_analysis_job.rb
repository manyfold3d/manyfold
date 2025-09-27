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
      mesh = file.mesh
      if mesh
        status[:step] = "jobs.analysis.geometric_analysis.manifold_check" # i18n-tasks-use t('jobs.analysis.geometric_analysis.manifold_check')
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
        # i18n-tasks-use t('jobs.analysis.geometric_analysis.direction_check')
        # status[:step] = "jobs.analysis.geometric_analysis.direction_check"
        #   Problem.create_or_clear(
        #     file,
        #     :inside_out,
        #     !mesh.solid?
        #   )
        # end
        if SiteSettings.generate_progressive_meshes && mesh.manifold?
          pmesh = Mittsu::MeshAnalysis::ProgressiveMesh.new(
            file.mesh.geometry,
            file.mesh.material
          )
          pmesh.progressify(ratio: 0.9)
          exporter = Mittsu::GLTFExporter.new
          Tempfile.create do |f|
            exporter.export(pmesh, f.path, mode: :binary)
            f.rewind
            file.attachment_attacher.add_derivatives({progressive: f})
            file.save(touch: false)
          end
        end
      else
        raise MeshLoadError.new
      end
    end
  end
end
