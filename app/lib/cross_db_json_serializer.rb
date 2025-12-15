module CrossDbJsonSerializer
  def self.load(payload)
    payload.is_a?(String) ? JSON.load(payload) : payload # rubocop:disable Security/JSONLoad
  end

  def self.dump(payload)
    payload.is_a?(String) ? payload : JSON.dump(payload)
  end
end
