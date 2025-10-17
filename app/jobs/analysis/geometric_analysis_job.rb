class MeshLoadError < StandardError
end

class Analysis::GeometricAnalysisJob < ApplicationJob
  queue_as :performance
  sidekiq_options retry: false
  unique :until_executed

  def perform(file_id)
    # Get model
    file = ModelFile.find(file_id)
    return unless self.class.loader(file)
    if SiteSettings.analyse_manifold
      status[:step] = "jobs.analysis.geometric_analysis.loading_mesh" # i18n-tasks-use t('jobs.analysis.geometric_analysis.loading_mesh')
      # Get mesh
      mesh = self.class.load_mesh(file)
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
      else
        raise MeshLoadError.new
      end
    end
  end

  def self.loader(file)
    case file.extension.downcase
    when "stl"
      Mittsu::STLLoader
    when "obj"
      Mittsu::OBJLoader
    end
  end

  def self.load_mesh(file)
    # TODO: This can be better, but needs changes upstream in Mittsu to allow loaders to parse from an IO object
    loader(file)&.new&.parse(file.attachment.read)
  end
end
