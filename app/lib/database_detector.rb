module DatabaseDetector
  def self.server
    case ActiveRecord::Base.connection.adapter_name
    when "PostgreSQL"
      :postgresql
    when "Mysql2"
      :mysql
    when "SQLite"
      :sqlite
    else
      raise NotImplementedError.new("Unknown database adapter #{ApplicationRecord.connection.adapter_name}")
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
end
