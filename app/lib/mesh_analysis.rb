module Mittsu
  class Geometry
    def manifold?
      edges = {}
      # For each face, record its edges in the edge hash
      @faces.each do |face|
        update_edge_hash face.a, face.b, edges
        update_edge_hash face.b, face.c, edges
        update_edge_hash face.c, face.a, edges
      end
      # If there's anything left in the edge hash, then either
      # we have holes, or we have badly oriented faces
      edges.empty?
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

  class BufferGeometry
    def manifold?
      true
    end
  end
end
