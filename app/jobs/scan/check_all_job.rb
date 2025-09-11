class Scan::CheckAllJob < ApplicationJob
  include JobIteration::Iteration

  queue_as :scan
  unique :until_executed

  def build_enumerator(filter_params, instigator, cursor:)
    scope = instigator ?
      ModelPolicy::UpdateScope.new(instigator, Model).resolve :
      Model.all
    scope = Search::FilterService.new(filter_params).models(scope)
    Rails.logger.info "queueing rescan for #{scope.count} models"
    enumerator_builder.active_record_on_records(scope, cursor: cursor)
  end

  def each_iteration(model, _filters, _instigator)
    model.check_later
  end
end
