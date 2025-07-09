class UppyCompanionController < ApplicationController
  protect_from_forgery with: :exception

  def url_meta
    authorize :model, :new?
    uri = URI.parse(params[:url])
    if ["https", "http"].include?(uri.scheme)
      # Do HEAD request for url
      response = Faraday.head uri
      render json: {
        name: uri.path.split("/").last,
        type: response.headers["content-type"],
        size: response.headers["content-length"].to_i,
        status_code: response.status
      }
    else
      head :bad_request
    end
  rescue URI::InvalidURIError
    head :bad_request
  end

  def url_get
    authorize :model, :new?
    Faraday.get params[:url]
    render status: :internal_server_error, json: {}
  end
end
