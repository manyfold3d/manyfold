class ActivityController < ApplicationController
  before_action { authorize :activity }

  after_action :verify_authorized
  skip_after_action :verify_policy_scoped, only: :index

  EXCLUSIONS = [
    "CacheSweepJob",
    "DownloadsSweepJob",
    "FaspClient::LifecycleAnnouncementJob"
  ]

  def index
    @jobs = ActiveJob::Status.all.sort_by { it.last_activity || "" }.reverse # rubocop:disable Pundit/UsePolicyScope
    @jobs.reject! { EXCLUSIONS.include? it.read.dig(:serialized_job, "job_class") }
    @pagy, @jobs = pagy(:offset, @jobs, limit: 50)
  end
end
