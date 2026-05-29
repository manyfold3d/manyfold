class FileHandlers::Lychee < FileHandlers::Base
  # i18n-tasks-use t('model_files.download.lychee')

  ENVIRONMENTS = [:client].freeze

  # https://doc.mango3d.io/doc/filament-documentation/filament-toolbar/import-2/
  INPUT_TYPES = Mime::EXTENSION_LOOKUP.slice("3mf", "lys", "obj", "stl").values.freeze

  def self.open_url_for(target, client_os: nil)
    URI::Generic.new(
      "lycheeslicer", nil,
      "open", nil, nil, CGI.escapeURIComponent(target), nil,
      nil, nil
    ).to_s
  end
end
