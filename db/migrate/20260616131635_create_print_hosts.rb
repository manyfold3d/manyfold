class CreatePrintHosts < ActiveRecord::Migration[8.0]
  def change
    create_table :print_hosts do |t|
      t.string :name
      t.string :protocol
      t.string :endpoint
      t.string :credentials

      t.timestamps
    end
  end
end
