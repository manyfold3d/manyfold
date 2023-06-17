# frozen_string_literal: true

class GenerateSlugs < ActiveRecord::Migration[7.0]
  def up
    Model.where(slug: nil) do |model|
      model.send(:slugify_name)
      model.save!(validate: false)
    end
    Creator.where(slug: nil) do |creator|
      creator.send(:slugify_name)
      creator.save!(validate: false)
    end
    Collection.where(slug: nil) do |collection|
      collection.send(:slugify_name)
      collection.save!(validate: false)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
