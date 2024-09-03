# frozen_string_literal: true

class HealthController < ApplicationController
  after_action :verify_policy_scoped, except: :index

  def index
    render json: {status: "OK"}, status: :ok
  end
end
