class AddImagesToCreators < ActiveRecord::Migration[8.0]
  def change
    add_column :creators, :avatar_data, :json
    add_column :creators, :banner_data, :json
  end
end
