# This migration comes from federails (originally 20250122160618)
class AddExtensionsToFederailsActors < ActiveRecord::Migration[7.1]
  def change
    add_column :federails_actors, :extensions, :json, default: nil, null: true
  end
end
