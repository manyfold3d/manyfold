class FileHandlers::FlockXR < FileHandlers::Base
  # i18n-tasks-use t('model_files.download.flockxr')

  class << self
    def environments
      [:client]
    end

    def input_types
      Mime::EXTENSION_LOOKUP.slice("flock").values
    end

    def open_url_for(target, client_os: nil)
      URI::Generic.new(
        "https", nil,
        "app.flockxr.com", nil, nil, nil, nil,
        {project: target}.to_query, nil
      ).to_s
    end
  end
end
