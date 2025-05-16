module Filterable
  extend ActiveSupport::Concern
  included do
    before_action :get_filters, only: [:index, :show] # rubocop:todo Rails/LexicallyScopedActionFilter
  end

  def get_filters
    # Get list filters from URL
    @filters = params.permit(:library, :collection, :q, :creator, :link, :missingtag, tag: [])
  end

  def filtered_models(filters)
    models = policy_scope(Model).all
    models = filter_by_library(models, filters[:library])
    models = filter_by_missing_tag(models, filters[:missingtag], filters[:library])
    models = filter_by_tag(models, filters[:tag])
    models = filter_by_collection(models, filters[:collection])
    models = filter_by_creator(models, filters[:creator])
    models = filter_by_url(models, filters[:link])
    filter_by_search(models, filters[:q])
  end

  def filtered_collections(filters)
    collections = policy_scope(Collection).includes(:creator)
    collections = filter_collection_by_collection(collections, filters[:collection])
    collections = filter_collection_by_creator(collections, filters[:creator])
    filter_by_search(collections, filters[:q])
  end

  private

  def filter_collection_by_collection(collections, collection)
    case collection
    when nil
      collections
    when ""
      collections.where(collection: nil)
    else
      collections.where(collection: Collection.find_param(collection))
    end
  end

  def filter_collection_by_creator(collections, creator)
    case creator
    when nil
      collections
    when ""
      collections.where(creator_id: nil)
    else
      collections.where(creator: Creator.find_param(creator))
    end
  end

  # Filter by library
  def filter_by_library(models, library)
    library ? models.where(library: Library.find_param(library)) : models
  end

  # Filter by collection
  def filter_by_collection(models, collection)
    case collection
    when nil
      models # No collection, move along
    when ""
      models.where(collection_id: nil)
    else
      @collection = Collection.find_param(collection)
      models.where(collection: Collection.tree_down(@collection.id))
    end
  end

  # Filter by creator
  def filter_by_creator(models, creator)
    case creator
    when nil
      models # No creator specified, nothing to do
    when ""
      models.where(creator_id: nil)
    else
      @creator = Creator.find_param(creator)
      models.where(creator: @creator)
    end
  end

  # Filter by tag
  def filter_by_tag(models, tags)
    case tags
    when nil
      models # No tags, move along
    when [""]
      models.where("(select count(*) from taggings where taggings.taggable_id=models.id and taggings.context='tags')<1")
    else
      @filter_tags = ActsAsTaggableOn::Tag.named_any(tags)
      # Build query directly rather than using tagged_with, which parses the tag list again using default separators
      ::ActsAsTaggableOn::Taggable::TaggedWithQuery.build(models, ActsAsTaggableOn::Tag, ActsAsTaggableOn::Tagging, @filter_tags.map(&:name), {})
    end
  end

  # Filter by url
  def filter_by_url(models, url)
    case url
    when nil
      models # no filter
    when ""
      models.where("(select count(*) from links where linkable_id=models.id and linkable_type='Model')<1")
    else
      models.where("(select count(*) from links where linkable_id=models.id and linkable_type='Model' and url like ?)>0", "%#{url}%")
    end
  end

  # Filter by search query
  def filter_by_search(models, query)
    if query
      Search::ModelSearchService.new(models).search(query)
    else
      models
    end
  end

  def filter_by_missing_tag(models, missingtag, library)
    # Missing tags (If specific tag is not specified, require library to be set)
    if missingtag.presence || (missingtag && library)
      tag_regex_build = []
      regexes = ((missingtag != "") ? [missingtag] : Library.find_param(library).tag_regex)
      # Regexp match syntax - postgres is different from MySQL and SQLite
      regact = (ApplicationRecord.connection.adapter_name == "PostgreSQL") ? "~" : "REGEXP"
      regexes.each do |reg|
        qreg = ActiveRecord::Base.connection.quote(reg)
        tag_regex_build.push "(select count(*) from tags join taggings on tags.id=taggings.tag_id where tags.name #{regact} #{qreg} and taggings.taggable_id=models.id and taggings.taggable_type='Model')<1"
      end
      qreg = ActiveRecord::Base.connection.quote(missingtag)
      tag_regex_build.push "(select count(*) from tags join taggings on tags.id=taggings.tag_id where tags.name #{regact} #{qreg} and taggings.taggable_id=models.id and taggings.taggable_type='Model')<1"
      models.where("(" + tag_regex_build.join(" OR ") + ")")
    else
      models
    end
  end
end
