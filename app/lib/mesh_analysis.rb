module MeshAnalysis
  def solid?
    # Shortcut if there is nothing here
    return true if geometry.nil? && children.empty?
    # Recurse children to see if they are solid
    children_are_solid = children.map { |x| x.solid? }.all?
    solid = true
    if geometry
      # Make sure material is double sided
      prev_side = material.side
      material.side = Mittsu::DoubleSide
      # Make a raycaster from a vertex and the face normal
      face = geometry.faces.first
      r = Mittsu::Raycaster.new(geometry.vertices[face.b], face.normal, 1e-9)
      intersections = r.intersect_object(self, true)
      # Restore material
      material.side = prev_side
      # We want an even number of intersections
      solid = (intersections.length % 2 == 0)
    end
    solid && children_are_solid
  end

  def manifold?
    # Shortcut if there is nothing here
    return true if geometry.nil? && children.empty?
    # Recurse children to see if they are manifold
    children_are_manifold = children.map { |x| x.manifold? }.all?
    # Detect manifold geometry in this object
    edges = {}
    # For each face, record its edges in the edge hash
    geometry&.faces&.each do |face|
      update_edge_hash face.a, face.b, edges
      update_edge_hash face.b, face.c, edges
      update_edge_hash face.c, face.a, edges
    end
    # If there's anything left in the edge hash, then either
    # we have holes, or we have badly oriented faces
    edges.empty? && children_are_manifold
  end

  private

  # Updates edge hash with the passed vertex indexes
  # First, the reverse edge is searched for in the hash
  # If found, it's removed as we've got a match
  # If not, we record this edge in the hash
  def update_edge_hash(v1, v2, edges)
    return if edges.delete "#{v2}->#{v1}"
    edges["#{v1}->#{v2}"] = true
  end
end

module Mittsu
  class Object3D
    include MeshAnalysis
  end

  class Face3
    def flip!
      tmp = @a
      @a = @c
      @c = tmp
    end
  end
end
