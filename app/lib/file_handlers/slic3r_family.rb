class FileHandlers::Slic3rFamily < FileHandlers::Base
  ENVIRONMENTS = [:client].freeze

  def self.scheme
    raise NotImplementedError
  end

  def self.open_url_for(target, client_os: nil)
    URI::Generic.new(
      scheme, nil,
      "open", nil, nil, nil, nil,
      {file: target}.to_query, nil
    ).to_s
  end
end
