class BenchmarkController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :login_as_admin
  before_action :load_random_model

  # Based on https://fractaledmind.github.io/2024/04/15/sqlite-on-rails-the-how-and-why-of-optimal-performance/
  # this controller is designed for benchmarking database write performance
  # and locking behaviour.

  # GET /benchmark to do reads:
  # `oha http://localhost:3214/benchmark`

  # POST /benchmark to do writes
  # `oha http://localhost:3214/benchmark -m POST`
  # or for a more aggressive test:
  # `oha -c 4 -z 5s -m POST --latency-correction --disable-keepalive --redirect 0 http://localhost:3214/benchmark`

  # Read a random model
  def index
    render json: {
      model: @model,
      files: @model.model_files
    }
  end

  # Write a random model
  def create
    @model.update!(name: @model.name.reverse)
    render json: @model, status: :created
  end

  private

  def login_as_admin
    # This should never be used in production, and routes.rb
    # should stop it happening, but *just in case* we'll check
    # here as well and explode if we're in prod.
    raise ActionController::BadRequest if Rails.env.production?
    sign_in(:user, User.with_role(:administrator).first)
  end

  def load_random_model
    @model = policy_scope(Model).find(policy_scope(Model).pluck(:id).sample)
    authorize @model
  end
end
