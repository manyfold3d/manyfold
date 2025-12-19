class AddTourStateToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :tour_state, :json
  end
end
