# frozen_string_literal: true

class MoveCollectionTagIntoObject < ActiveRecord::Migration[7.0]
  def up
    Model.all.each do |model|
      if defined?(model.collections) && !model.collection
        model.collections.each do |collection|
          newcol = Collection.find_by name: collection.name
          if !newcol
            newcol = Collection.create(name: collection.name)
          end
          newcol.models << model
          newcol.save
        end
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
