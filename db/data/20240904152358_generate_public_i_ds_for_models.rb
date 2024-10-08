# frozen_string_literal: true

class GeneratePublicIDsForModels < ActiveRecord::Migration[7.1]
  def up
    [Model, ModelFile, Problem, Creator, Collection, Library].each do |model|
      model.where(public_id: nil).find_each do |obj|
        obj.send :generate_public_id
        obj.update_column :public_id, obj.public_id # rubocop:disable Rails/SkipsModelValidations
      end
    end
  end

  def down
  end
end
