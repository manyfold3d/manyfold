# frozen_string_literal: true

class GeneratePublicIDsForModels < ActiveRecord::Migration[7.1]
  def up
    [Model, ModelFile, Problem, Creator, Collection, Library].each do |model|
      model.find_each do |obj|
        obj.send :generate_public_id
        obj.save! validate: false
      end
    end
  end

  def down
  end
end
