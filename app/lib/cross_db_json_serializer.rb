module CrossDbJsonSerializer
  def self.load(payload)
    return if payload.nil?
    case ApplicationRecord.connection.adapter_name
    when "Mysql2" # Actually this is the behaviour for MariaDB
      payload.is_a?(String) ? JSON.parse(payload) : payload
    else
      payload
    end
  end

  def self.dump(payload)
    return if payload.nil?
    case ApplicationRecord.connection.adapter_name
    when "Mysql2" # Actually this is the behaviour for MariaDB
      payload.is_a?(String) ? payload : JSON.generate(payload)
    else
      payload
    end
  end
end
