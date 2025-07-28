class Scan::CheckAllJob < ApplicationJob
  queue_as :scan
  unique :until_executed

  def perform
    # Check all models
    status[:step] = "jobs.scan.check_all.queueing_model_checks" # i18n-tasks-use t('jobs.scan.check_all.queueing_model_checks')
    Model.find_each(&:check_later)
  end
end
