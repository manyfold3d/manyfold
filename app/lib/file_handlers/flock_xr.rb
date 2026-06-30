class FileHandlers::FlockXr < FileHandlers::Base
  # i18n-tasks-use t('model_files.download.flock_xr')

  ENVIRONMENTS = [:client].freeze
  INPUT_TYPES = Mime::EXTENSION_LOOKUP.slice("flock").values.freeze

  def self.open_url_for(file, client_os: nil)
    URI::Generic.new(
      "https", nil,
      "app.flockxr.com", nil, nil, nil, nil,
      {project: signed_url_for(file)}.to_query, nil
    ).to_s
  end

  def self.icon
    "images/external-icons/flock_xr.png"
  end
end
