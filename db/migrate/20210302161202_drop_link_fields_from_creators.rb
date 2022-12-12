class DropLinkFieldsFromCreators < ActiveRecord::Migration[6.1]
  def change
    remove_column :creators, :thingiverse_user, :string
    remove_column :creators, :cults3d_user, :string
    remove_column :creators, :mmf_user, :string
    remove_column :creators, :cgtrader_user, :string
  end
end
