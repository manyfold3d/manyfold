class RansackTransformer
  def initialize(terms)
    @terms = terms
  end

  def ransack_options
    search = @terms.join(" ")
    {
      m: "or",
      name_cont: search,
      tags_name_in: search,
      creator_name_cont: search,
      collection_name_cont: search
    }
  end

  def perform(scope)
    scope.ransack(ransack_options).result(distinct: true)
  end
end
