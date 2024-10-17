class AddSensitiveContentHandlingToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :sensitive_content_handling, :string, default: nil
  end
end
