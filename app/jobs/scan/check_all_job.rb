class Scan::CheckAllJob < ApplicationJob
  queue_as :scan
  unique :until_executed

  def perform
    # Remove orphan problems
    status[:step] = "jobs.scan.check_all.removing_orphaned_problems" # i18n-tasks-use t('jobs.scan.check_all.removing_orphaned_problems')
    Problem.including_ignored.find_each do |problem|
      problem.destroy if problem.problematic.nil?
    end
    # Check all models
    status[:step] = "jobs.scan.check_all.queueing_model_checks" # i18n-tasks-use t('jobs.scan.check_all.queueing_model_checks')
    Model.find_each do |model|
      model.check_later(scan: false)
    end
  end
end
