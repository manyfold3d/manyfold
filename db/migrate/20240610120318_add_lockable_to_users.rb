class AddLockableToUsers < ActiveRecord::Migration[7.0]
  def change
      ## Lockable
      change_table :users do |t|
        t.integer  :failed_attempts, default: 0, null: false
        # t.string   :unlock_token # Only if unlock strategy is :email or :both
        t.datetime :locked_at
      end
  end
end
