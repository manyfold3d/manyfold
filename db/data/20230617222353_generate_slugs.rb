# frozen_string_literal: true

class GenerateSlugs < ActiveRecord::Migration[7.0]
  def up
    Model.where(slug: nil).find_each do |model|
      model.send(:slugify_name)
      model.save!(validate: false)
    end
    Creator.where(slug: nil).find_each do |creator|
      creator.send(:slugify_name)
      creator.save!(validate: false)
    end
    Collection.where(slug: nil).find_each do |collection|
      collection.send(:slugify_name)
      collection.save!(validate: false)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
