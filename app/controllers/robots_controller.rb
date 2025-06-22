class RobotsController < ActionController::Base # rubocop:disable Rails/ApplicationController
  protect_from_forgery with: :exception
  include Pundit::Authorization

  def index
    respond_to do |format|
      format.text
    end
  end

  def sitemap
    @creators = CreatorPolicy::Scope.new(nil, Creator).resolve.local.filter(&:indexable?)
    @collections = CollectionPolicy::Scope.new(nil, Collection).resolve.local.filter(&:indexable?)
    @models = ModelPolicy::Scope.new(nil, Model).resolve.local.filter(&:indexable?)
    respond_to do |format|
      format.xml
    end
  end
end
