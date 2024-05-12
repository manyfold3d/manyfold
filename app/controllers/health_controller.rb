# frozen_string_literal: true

# rubocop:disable Rails/ApplicationController
class HealthController < ActionController::Base
  # rubocop:enable Rails/ApplicationController
  after_action :verify_policy_scoped, except: :index

  def index
    render json: {status: "OK"}, status: :ok
  end
end
