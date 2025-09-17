require "thor"

module Cli
  class FaspCommand < Thor
    COMMAND = "fasp"
    DESCRIPTION = "interact with FASP servers"

    desc "announce", "push all public indexable content to connected FASPs"
    def prune
      [
        Model,
        Creator,
        Collection
      ].each do |it|
        Pundit::PolicyFinder.new(it).scope.new(nil, it).resolve.each do |x|
          x.send :fasp_emit_lifecycle_announcement, "new"
        end
      end
    end
  end
end
