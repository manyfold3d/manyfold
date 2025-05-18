class Search::ModelSearchService
  def initialize(scope)
    @scope = scope
  end

  def search(query)
    if ApplicationRecord.connection.adapter_name == "PostgreSQL"
      @scope.where(
        Model.select("DISTINCT ON (models.id) models.*") # rubocop:disable Pundit/UsePolicyScope
          .search_for(query)
          .pluck(:id) # rubocop:todo Rails/PluckInWhere
      )
    else
      @scope.search_for(query).distinct
    end
  end
end
