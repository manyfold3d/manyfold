class FileHandlers::Lychee < FileHandlers::Base
  # i18n-tasks-use t('model_files.download.lychee')

  class << self
    def environments
      [:client]
    end

    def input_types
      # https://doc.mango3d.io/doc/filament-documentation/filament-toolbar/import-2/
      Mime::EXTENSION_LOOKUP.slice("3mf", "lys", "obj", "stl").values
    end

    def open_url_for(target, client_os: nil)
      URI::Generic.new(
        "lycheeslicer", nil,
        "open", nil, nil, CGI.escapeURIComponent(target), nil,
        nil, nil
      ).to_s
    end
  end
end
