class ActivityController < ApplicationController
  before_action { authorize :activity }

  after_action :verify_authorized
  skip_after_action :verify_policy_scoped, only: :index

  EXCLUSIONS = [
    "CacheSweepJob"
  ]

  def index
    @jobs = ActiveJob::Status.all.sort_by { |x| x.last_activity || "" }.reverse
    @jobs.reject! { |x| EXCLUSIONS.include? x.read.dig(:serialized_job, "job_class") }
    @jobs = Kaminari.paginate_array(@jobs).page(params[:page]).per(50)
  end
end
