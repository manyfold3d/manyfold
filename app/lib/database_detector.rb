module DatabaseDetector
  class << self
    extend Memoist

    def server
      ActiveRecord::Base.with_connection do |connection|
        case connection.adapter_name
        when "PostgreSQL"
          :postgresql
        when "Mysql2"
          :mysql
        when "SQLite"
          :sqlite
        when "NullDB"
          :null
        else
          raise NotImplementedError.new("Unknown database adapter #{connection.adapter_name}")
        end
      end
    end
    memoize :server

    def is_mysql?
      server == :mysql
    end
    memoize :is_mysql?

    def is_mariadb?
      is_mysql?
    end
    memoize :is_mariadb?

    def is_postgres?
      server == :postgresql
    end
    memoize :is_postgres?

    def is_sqlite?
      server == :sqlite
    end
    memoize :is_sqlite?

    def table_ready?(table_name)
      ActiveRecord::Base.with_connection do |connection|
        connection.data_source_exists? table_name
      end
    end
    memoize :table_ready?
  end
end
