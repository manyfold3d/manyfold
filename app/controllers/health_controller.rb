# frozen_string_literal: true

class HealthController < ApplicationController
  after_action :verify_policy_scoped, except: :index
  skip_before_action :authenticate_user!, if: -> { !SiteSettings.multiuser_enabled? }
  skip_before_action :check_for_first_use

  def index
    render json: {status: "OK"}, status: :ok
  end
end
