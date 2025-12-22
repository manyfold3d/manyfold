if DatabaseDetector.is_sqlite?
  ActiveRecord::Base.with_connection do |connection|
    # Set temp_store to use memory, not disk
    connection.execute "PRAGMA temp_store=MEMORY;"
  end
end
