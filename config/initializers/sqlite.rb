connection = ActiveRecord::Base.connection
if connection&.is_a? ActiveRecord::ConnectionAdapters::SQLite3Adapter
  # Set temp_store to use memory, not disk
  connection.execute "PRAGMA temp_store=MEMORY;"
end
