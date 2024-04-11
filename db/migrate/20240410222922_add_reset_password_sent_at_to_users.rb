class AddResetPasswordSentAtToUsers < ActiveRecord::Migration[7.0]
  def change
    ## Devise/Recoverable
    add_column :users, :reset_password_sent_at, :datetime
  end
end
