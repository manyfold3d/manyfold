class Federails::Server::QuoteAuthorizationsController < ApplicationController
  def show
    skip_authorization
    @quote_authorization = Federails::QuoteAuthorization.find_by!(uuid: params["id"]) # rubocop:disable Pundit/UsePolicyScope
    respond_to do |format|
      format.activitypub
    end
  end
end
