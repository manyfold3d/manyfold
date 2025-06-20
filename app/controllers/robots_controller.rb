class RobotsController < ActionController::Base # rubocop:disable Rails/ApplicationController
  protect_from_forgery with: :exception

  def index
    if SiteSettings.allow_robots
      head :not_found
    else
      respond_to do |format|
        format.text
      end
    end
  end

  def sitemap
    respond_to do |format|
      format.xml
    end
  end
end
