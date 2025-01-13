class UppyCompanionController < ApplicationController
  skip_forgery_protection

  def url_meta
    authorize :model, :new?
    # Do HEAD request for url
    response = Faraday.head params[:url]
    render json: {
      name: response.headers["filename"],
      type: response.headers["content-type"],
      size: response.headers["content-length"],
      status_code: response.status
    }
  end

  def url_get
    authorize :model, :new?
    Faraday.get params[:url]
    render status: :internal_server_error, json: {}
  end
end
