module DatabaseDetector
  def self.server
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

  def self.is_mysql?
    server == :mysql
  end

  def self.is_mariadb?
    is_mysql?
  end

  def self.is_postgres?
    server == :postgresql
  end

  def self.is_sqlite?
    server == :sqlite
  end

  def self.table_ready?(table_name)
    ActiveRecord::Base.with_connection do |connection|
      connection.data_source_exists? table_name
    end
  end
end
