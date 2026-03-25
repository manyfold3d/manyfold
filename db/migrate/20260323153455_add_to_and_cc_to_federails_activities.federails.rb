# This migration comes from federails (originally 20251121160720)
class AddToAndCcToFederailsActivities < ActiveRecord::Migration[7.2]
  def change
    add_column :federails_activities, :to, :string
    add_column :federails_activities, :cc, :string
  end
end
