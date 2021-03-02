class DropLinkFieldsFromCreators < ActiveRecord::Migration[6.1]
  def change
    remove_column :creators, :thingiverse_user
    remove_column :creators, :cults3d_user
    remove_column :creators, :mmf_user
    remove_column :creators, :cgtrader_user
  end
end
