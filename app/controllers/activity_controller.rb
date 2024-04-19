class ActivityController < ApplicationController
  before_action { authorize :activity }

  after_action :verify_authorized
  skip_after_action :verify_policy_scoped, only: :index

  def index
    @jobs = ActiveJob::Status.store.redis.keys("activejob:status:*").
              map{ |x| ActiveJob::Status.get(x.split(":").last) }.
              sort_by{ |x| [x[:enqueued_at], x[:started_at], x[:finished_at], DateTime.new(0)].compact.max }.
              reverse
  end
end
