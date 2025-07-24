class ImportsController < ApplicationController
  skip_after_action :verify_policy_scoped
  before_action :get_url

  def new
  end

  def create
    CreateObjectFromUrlJob.perform_later(url: @url, owner: current_user)
    redirect_to root_url, notice: t(".success")
  end

  private

  def get_url
    @url = params[:url]
    @deserializer = Link.deserializer_for(url: @url)
    authorize @deserializer.capabilities[:class]
  end
end
