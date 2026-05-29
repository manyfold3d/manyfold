class FileHandlers::FlockXr < FileHandlers::Base
  # i18n-tasks-use t('model_files.download.flock_xr')

  ENVIRONMENTS = [:client].freeze
  INPUT_TYPES = Mime::EXTENSION_LOOKUP.slice("flock").values.freeze

  def self.open_url_for(target, client_os: nil)
    URI::Generic.new(
      "https", nil,
      "app.flockxr.com", nil, nil, nil, nil,
      {project: target}.to_query, nil
    ).to_s
  end
end
