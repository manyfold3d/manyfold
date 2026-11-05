class FileHandlers::Freecad < FileHandlers::Base
  # i18n-tasks-use t('model_files.download.freecad')

  ENVIRONMENTS = [:client].freeze

  INPUT_TYPES = Mime::LOOKUP.slice(:threemf, :fcstd, :iges, :obj, :step, :stl).values.freeze

  def self.open_url_for(file, client_os: nil)
    URI::Generic.new(
      "ondsel", nil,
      CGI.escapeURIComponent(signed_url), nil, nil, nil, nil,
      nil, nil
    ).to_s
  end

  def self.icon
    "images/external-icons/freecad.png"
  end
end
