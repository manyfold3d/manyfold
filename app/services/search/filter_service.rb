# frozen_string_literal: true

class Search::FilterService
  PERMITTED_FILTER_KEYS = [
    :library,
    :collection,
    :q,
    :creator,
    :link,
    :missingtag,
    :owner,
    :has_image,
    :list,
    {tag: []}
  ].freeze

  attr_reader :collection
  attr_reader :creator
  attr_reader :owner

  def initialize(params, user: nil, default_has_image: false)
    @user = user
    raw = normalize_params(params)
    has_image_specified = param_key?(raw, :has_image)
    @filters = permit_filters(raw)
    %i[library collection creator].each do |key|
      @filters.delete(key) if @filters[key].to_s == "all"
    end
    @filters.delete(:link) if @filters[:link].blank?
    @filters.delete(:q) if @filters[:q].blank?
    normalize_has_image!(has_image_specified: has_image_specified, default_has_image: default_has_image)
    @filters.delete(:list) unless %w[favorite printed queue unprinted].include?(@filters[:list].to_s)

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
    except ? @filters.except(except) : @filters
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
    scope = filter_by_has_image(scope)
    scope = filter_by_list(scope)
    filter_by_search(scope)
  end

  def collections(scope)
    scope = scope.includes(:creator)
    scope = filter_by_owner(scope)
    scope = filter_by_collection(scope)
    scope = filter_by_creator(scope)
    filter_by_search(scope)
  end

  def creators(creator_scope, models)
    creator_scope = creator_scope.where(id: models.pluck(:creator_id).uniq)
    filter_by_owner(creator_scope)
  end

  def tags
    ActsAsTaggableOn::Tag.named_any(parameter(:tag)) if filtering_by?(:tag)
  end

  private

  def normalize_params(params)
    case params
    when ActionController::Parameters
      params.to_unsafe_h
    when Hash
      params.stringify_keys
    else
      params.to_h.stringify_keys
    end
  end

  def permit_filters(raw)
    ActionController::Parameters.new(raw).permit(*PERMITTED_FILTER_KEYS).to_h.symbolize_keys
  end

  def filter_by_library(scope)
    filtering_by?(:library) ? scope.where(library: Library.find_param(parameter(:library))) : scope
  end

  def filter_by_collection(scope)
    case parameter(:collection)
    when nil
      scope
    when ""
      scope.where(collection_id: nil)
    else
      scope.where(collection: Collection.tree_down(@collection.id))
    end
  end

  def filter_by_creator(scope)
    case parameter(:creator)
    when nil
      scope
    when ""
      scope.where(creator_id: nil)
    else
      scope.where(creator: creator)
    end
  end

  def filter_by_owner(scope)
    owner ? scope.granted_to("own", owner).local : scope
  end

  def filter_by_tag(scope)
    case parameter(:tag)
    when nil
      scope
    when [""]
      scope.where("(select count(*) from taggings where taggings.taggable_id=models.id and taggings.taggable_type='Model')<1")
    else
      ::ActsAsTaggableOn::Taggable::TaggedWithQuery.build(scope, ActsAsTaggableOn::Tag, ActsAsTaggableOn::Tagging, parameter(:tag), {})
    end
  end

  def filter_by_url(scope)
    case parameter(:link)
    when nil
      scope
    when ""
      scope.where("(select count(*) from links where linkable_id=models.id and linkable_type='Model')<1")
    else
      scope.where("(select count(*) from links where linkable_id=models.id and linkable_type='Model' and url like ?)>0", "%#{parameter(:link)}%")
    end
  end

  def filter_by_search(scope)
    if parameter(:q)
      Search::ModelSearchService.new(scope).search(parameter(:q))
    else
      scope
    end
  end

  def filter_by_missing_tag(scope)
    if filtering_by?(:missingtag) || (filtering_by?(:missingtag) && parameter(:library))
      tag_regex_build = []
      regexes = ((parameter(:missingtag) != "") ? [parameter(:missingtag)] : Library.find_param(parameter(:library)).tag_regex)
      regact = DatabaseDetector.is_postgres? ? "~" : "REGEXP"
      regexes.each do |reg|
        qreg = ActiveRecord::Base.with_connection { |conn| conn.quote(reg) }
        tag_regex_build.push "(select count(*) from tags join taggings on tags.id=taggings.tag_id where tags.name #{regact} #{qreg} and taggings.taggable_id=models.id and taggings.taggable_type='Model')<1"
      end
      qreg = ActiveRecord::Base.with_connection { |conn| conn.quote(parameter(:missingtag)) }
      tag_regex_build.push "(select count(*) from tags join taggings on tags.id=taggings.tag_id where tags.name #{regact} #{qreg} and taggings.taggable_id=models.id and taggings.taggable_type='Model')<1"
      scope.where("(" + tag_regex_build.join(" OR ") + ")")
    else
      scope
    end
  end

  def filter_by_has_image(scope)
    return scope unless truthy?(parameter(:has_image))

    # Delegate to Model.with_image_preview (EXISTS + filename_lower) — INIT-009/SPEC-005.
    return scope.none if SupportedMimeTypes.image_extensions.empty?

    scope.merge(Model.with_image_preview)
  end

  def filter_by_list(scope)
    return scope if @user.blank? || !filtering_by?(:list)

    case parameter(:list).to_s
    when "favorite"
      scope.where(id: @user.favorited_model_ids.to_a)
    when "queue"
      scope.where(id: @user.queued_model_ids.to_a)
    when "printed"
      scope.where(id: @user.printed_model_ids.to_a)
    when "unprinted"
      printed = @user.printed_model_ids
      printed.empty? ? scope : scope.where.not(id: printed.to_a)
    else
      scope
    end
  end

  def truthy?(value)
    ActiveModel::Type::Boolean.new.cast(value)
  rescue ArgumentError
    %w[1 true yes on].include?(value.to_s.downcase)
  end

  def param_key?(params, key)
    params.key?(key) || params.key?(key.to_s)
  end

  def normalize_has_image!(has_image_specified:, default_has_image:)
    raw = @filters[:has_image]
    raw = raw.last if raw.is_a?(Array)
    searching = @filters[:q].present?

    if !has_image_specified && default_has_image && !searching
      @filters[:has_image] = "1"
    elsif has_image_specified
      @filters[:has_image] = truthy?(raw) ? "1" : "0"
    else
      @filters.delete(:has_image)
    end
  end
end
