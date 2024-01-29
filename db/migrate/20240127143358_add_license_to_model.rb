class AddLicenseToModel < ActiveRecord::Migration[7.0]
  def change
    add_column :models, :license, :string
  end
end
