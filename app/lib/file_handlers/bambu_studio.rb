class FileHandlers::BambuStudio < FileHandlers::Slic3rFamily
  # i18n-tasks-use t('model_files.download.bambu_studio')
  class << self
    def input_types
      # Bambu Studio doesn't seem to open anything except 3MF by URL
      Mime::EXTENSION_LOOKUP.slice("3mf").values
    end

    def scheme
      "bambustudio"
    end

    def open_url_for(target, client_os: nil)
      if client_os&.family == "Mac OS X"
        URI::Generic.new(
          "bambustudioopen", nil,
          CGI.escapeURIComponent(target), nil, nil, nil, nil,
          nil, nil
        ).to_s
      else
        super
      end
    end
  end
end
