if DatabaseDetector.is_sqlite?
  # Set temp_store to use memory, not disk
  ActiveRecord::Base.connection.execute "PRAGMA temp_store=MEMORY;"
end
