class Scan::CheckAllJob < ApplicationJob
  queue_as :scan
  unique :until_executed

  include JobIteration::Iteration
  queue_as :scan
  unique :until_executed

  def build_enumerator(cursor:)
    scope = Model.all
    enumerator_builder.active_record_on_records(scope, cursor: cursor)
  end

  def each_iteration(model)
    model.check_later
  end
end
