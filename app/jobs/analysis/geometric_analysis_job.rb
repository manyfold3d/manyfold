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
        manifold = manifold?(mesh)
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

  private

  def manifold?(mesh)
    # Shortcut if there is nothing here
    return true if mesh.geometry.nil? && mesh.children.empty?
    # Recurse children to see if they are manifold
    children_are_manifold = mesh.children.map { |x| manifold?(x) }.all?
    # Detect manifold geometry in this object
    edges = {}
    # For each face, record its edges in the edge hash
    mesh.geometry&.faces&.each do |face|
      update_edge_hash face.a, face.b, edges
      update_edge_hash face.b, face.c, edges
      update_edge_hash face.c, face.a, edges
    end
    # If there's anything left in the edge hash, then either
    # we have holes, or we have badly oriented faces
    edges.empty? && children_are_manifold
  end

  # Updates edge hash with the passed vertex indexes
  # First, the reverse edge is searched for in the hash
  # If found, it's removed as we've got a match
  # If not, we record this edge in the hash
  def update_edge_hash(v1, v2, edges)
    return if edges.delete "#{v2}->#{v1}"
    edges["#{v1}->#{v2}"] = true
  end
end
