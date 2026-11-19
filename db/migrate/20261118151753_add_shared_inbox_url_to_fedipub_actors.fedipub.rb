# This migration comes from fedipub (originally 20260924090802)
class AddSharedInboxUrlToFedipubActors < ActiveRecord::Migration[7.2]
  def change
    add_column :fedipub_actors, :shared_inbox_url, :string
  end
end
