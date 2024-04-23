class AddInterfaceLanguageToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :interface_language, :string
  end
end
