require "thor"

module Cli
  class CreatorsCommand < Thor
    COMMAND = "creators"
    DESCRIPTION = "manage creators"

    desc "prune", "removes all creators that aren't associated with any models"
    def prune
      Creator.find_each { |it| it.destroy if it.models.empty? }
    end
  end
end
