class UppyCompanionController < ApplicationController
  before_action :check_auth
  before_action :validate_uri

  def url_meta
    response = Faraday.head @uri
    render json: {
      name: @uri.path.split("/").last,
      type: response.headers["content-type"],
      size: response.headers["content-length"].to_i,
      status_code: response.status
    }
  end

  def url_get
    response = Faraday.get @uri
    render status: response.status, json: {}
  end

  private

  def check_auth
    authorize :model, :new?
  end

  def validate_uri
    @uri = URI.parse(params.permit(uppy_companion: [:url]).dig(:uppy_companion, :url))
    head :bad_request unless ["https", "http"].include?(@uri.scheme)
  rescue URI::InvalidURIError
    head :bad_request
  end
end
