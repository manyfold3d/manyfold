class FileHandlers::BambuStudio < FileHandlers::Slic3rFamily
  # i18n-tasks-use t('model_files.download.bambu_studio')

  # Bambu Studio doesn't seem to open anything except 3MF by URL
  INPUT_TYPES = Mime::EXTENSION_LOOKUP.slice("3mf").values.freeze

  def self.scheme
    "bambustudio"
  end

  def self.icon
    "images/external-icons/bambu_studio.png"
  end

  def self.open_url_for(target, client_os: nil)
    os = client_os&.call
    if os&.family == "Mac OS X"
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
