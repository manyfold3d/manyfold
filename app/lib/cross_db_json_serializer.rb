module CrossDbJsonSerializer
  def self.load(payload)
    return if payload.nil?
    if DatabaseDetector.is_mariadb?
      payload.is_a?(String) ? JSON.parse(payload) : payload
    else
      payload
    end
  end

  def self.dump(payload)
    return if payload.nil?
    if DatabaseDetector.is_mariadb?
      payload.is_a?(String) ? payload : JSON.generate(payload)
    else
      payload
    end
  end
end
