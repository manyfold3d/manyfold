class FileHandlers::Slic3rFamily < FileHandlers::Base
  class << self
    def environments
      [:client]
    end

    def scheme
      raise NotImplementedError
    end

    def open_url_for(target, client_os: nil)
      URI::Generic.new(
        scheme, nil,
        "open", nil, nil, nil, nil,
        {file: target}.to_query, nil
      ).to_s
    end
  end
end
