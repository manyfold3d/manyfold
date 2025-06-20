class RobotsController < ActionController::Base # rubocop:disable Rails/ApplicationController
  protect_from_forgery with: :exception
  include Pundit::Authorization

  def index
    respond_to do |format|
      format.text
    end
  end

  def sitemap
    @creators = policy_scope(Creator).indexable
    @collections = policy_scope(Collection).indexable
    @models = policy_scope(Model).indexable
    respond_to do |format|
      format.xml
    end
  end
end
