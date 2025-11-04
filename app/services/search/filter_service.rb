class Search::FilterService
  attr_reader :collection
  attr_reader :creator
  attr_reader :owner

  # Get list filters from URL
  def initialize(params)
    params = ActionController::Parameters.new(params) if params.is_a?(Hash)
    @filters = params.permit(
      :library,
      :collection,
      :q,
      :creator,
      :link,
      :missingtag,
      :owner,
      tag: []
    )
    @collection = Collection.find_param(parameter(:collection)) if parameter(:collection).present?
    @creator = Creator.find_param(parameter(:creator)) if parameter(:creator).present?
    @owner = User.find_param(parameter(:owner)) if parameter(:owner).present?
  end

  def any?
    !@filters.empty?
  end

  def filtering_by?(key)
    parameter(key).present?
  end

  def parameter(key)
    @filters[key]
  end

  def to_params(except: nil)
    @filters.except(except)
  end

  def models(scope)
    scope = scope.all
    scope = filter_by_owner(scope)
    scope = filter_by_library(scope)
    scope = filter_by_missing_tag(scope)
    scope = filter_by_tag(scope)
    scope = filter_by_collection(scope)
    scope = filter_by_creator(scope)
    scope = filter_by_url(scope)
    filter_by_search(scope)
  end

  def collections(scope)
    scope = scope.includes(:creator)
    scope = filter_by_collection(scope)
    scope = filter_by_creator(scope)
    filter_by_search(scope)
  end

  def tags
    ActsAsTaggableOn::Tag.named_any(parameter(:tag)) if filtering_by?(:tag)
  end

  private

  # Filter by library
  def filter_by_library(scope)
    filtering_by?(:library) ? scope.where(library: Library.find_param(parameter(:library))) : scope
  end

  # Filter by collection
  def filter_by_collection(scope)
    case parameter(:collection)
    when nil
      scope # No collection, move along
    when ""
      scope.where(collection_id: nil)
    else
      scope.where(collection: Collection.tree_down(@collection.id))
    end
  end

  # Filter by creator
  def filter_by_creator(scope)
    case parameter(:creator)
    when nil
      scope # No creator specified, nothing to do
    when ""
      scope.where(creator_id: nil)
    else
      scope.where(creator: creator)
    end
  end

  def filter_by_owner(scope)
    scope
  end

  # Filter by tag
  def filter_by_tag(scope)
    case parameter(:tag)
    when nil
      scope # No tags, move along
    when [""]
      scope.where("(select count(*) from taggings where taggings.taggable_id=models.id and taggings.context='tags')<1")
    else
      # Build query directly rather than using tagged_with, which parses the tag list again using default separators
      ::ActsAsTaggableOn::Taggable::TaggedWithQuery.build(scope, ActsAsTaggableOn::Tag, ActsAsTaggableOn::Tagging, parameter(:tag), {})
    end
  end

  # Filter by url
  def filter_by_url(scope)
    case parameter(:link)
    when nil
      scope # no filter
    when ""
      scope.where("(select count(*) from links where linkable_id=models.id and linkable_type='Model')<1")
    else
      scope.where("(select count(*) from links where linkable_id=models.id and linkable_type='Model' and url like ?)>0", "%#{parameter(:link)}%")
    end
  end

  # Filter by search query
  def filter_by_search(scope)
    if parameter(:q)
      Search::ModelSearchService.new(scope).search(parameter(:q))
    else
      scope
    end
  end

  def filter_by_missing_tag(scope)
    # Missing tags (If specific tag is not specified, require library to be set)
    if filtering_by?(:missingtag) || (filtering_by?(:missingtag) && parameter(:library))
      tag_regex_build = []
      regexes = ((parameter(:missingtag) != "") ? [parameter(:missingtag)] : Library.find_param(parameter(:library)).tag_regex)
      # Regexp match syntax - postgres is different from MySQL and SQLite
      regact = (ApplicationRecord.connection.adapter_name == "PostgreSQL") ? "~" : "REGEXP"
      regexes.each do |reg|
        qreg = ActiveRecord::Base.connection.quote(reg)
        tag_regex_build.push "(select count(*) from tags join taggings on tags.id=taggings.tag_id where tags.name #{regact} #{qreg} and taggings.taggable_id=models.id and taggings.taggable_type='Model')<1"
      end
      qreg = ActiveRecord::Base.connection.quote(parameter(:missingtag))
      tag_regex_build.push "(select count(*) from tags join taggings on tags.id=taggings.tag_id where tags.name #{regact} #{qreg} and taggings.taggable_id=models.id and taggings.taggable_type='Model')<1"
      scope.where("(" + tag_regex_build.join(" OR ") + ")")
    else
      scope
    end
  end
end
