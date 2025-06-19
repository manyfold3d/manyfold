class RobotsController < ActionController::Base # rubocop:disable Rails/ApplicationController
  def index
    if SiteSettings.allow_robots
      head :not_found
    else
      respond_to do |format|
        format.text
      end
    end
  end
end
