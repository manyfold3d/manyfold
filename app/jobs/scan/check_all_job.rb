class Scan::CheckAllJob < ApplicationJob
  queue_as :scan
  unique :until_executed

  include JobIteration::Iteration
  queue_as :scan
  unique :until_executed

  def build_enumerator(filters, cursor:)
    scope = Model.all
    scope = Search::ModelSearchService.new(scope).search(filters[:q]) if filters[:q]
    Rails.logger.info "queueing rescan for #{scope.count} models"
    enumerator_builder.active_record_on_records(scope, cursor: cursor)
  end

  def each_iteration(model, _filters)
    model.check_later
  end
end
