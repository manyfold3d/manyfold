class Search::ModelSearchService
  def initialize(scope)
    base = scope.includes("federails_actor")
    @scope = base.where("federails_actor.local": true).or(
      base.where("federails_actor.local": false, indexable: "yes")
    )
  end

  def search(query)
    if DatabaseDetector.is_postgres?
      @scope.where(
        id: Model.select("DISTINCT ON (models.id) models.*") # rubocop:disable Pundit/UsePolicyScope
          .search_for(query)
          .pluck(:id) # rubocop:todo Rails/PluckInWhere
      )
    else
      @scope.search_for(query).distinct
    end
  end
end
