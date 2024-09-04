# frozen_string_literal: true

class GeneratePublicIDsForModels < ActiveRecord::Migration[7.1]
  def up
    [Model, ModelFile, Problem, Creator, Collection, Library].each do |model|
      model.find_each do |obj|
        obj.update_attribute(:public_id, model.generate_cool_id) # rubocop:disable Rails/SkipsModelValidations
      end
    end
  end

  def down
  end
end
