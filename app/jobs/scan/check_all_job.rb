class Scan::CheckAllJob < Upgrade::IterationJob
  queue_as :scan

  def build_enumerator(filter_params, instigator, cursor:)
    scope = instigator ?
      ModelPolicy::UpdateScope.new(instigator, Model).resolve :
      Model.all
    scope = Search::FilterService.new(filter_params).models(scope)
    Amiko.logger.info "queueing rescan for #{scope.count} models"
    enumerator_builder.active_record_on_records(scope, cursor: cursor)
  end

  def each_iteration(model, _filters, _instigator)
    model.check_later
  end
end
