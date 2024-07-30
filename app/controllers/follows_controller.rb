class FollowsController < ApplicationController
  before_filter :get_followable

  def create
  end

  def destroy
  end

  private

  def get_followable
    @followable = nil
  end
end
