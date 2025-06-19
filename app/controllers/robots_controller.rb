class RobotsController < ActionController::Base # rubocop:disable Rails/ApplicationController
  def index
    respond_to do |format|
      format.text
    end
  end
end
