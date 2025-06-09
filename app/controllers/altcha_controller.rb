class AltchaController < ApplicationController
  skip_after_action :verify_authorized

  def new
    render json: Altcha::Challenge.create.to_json
  end
end
