# Manyfold's own controller for manually managing and revoking access tokens

class DoorkeeperAccessTokensController < ApplicationController
  before_action :get_application
  before_action :get_token, except: [:new, :create]

  def show
    @plaintext_token = flash[:plaintext_token]
    raise ActiveRecord::RecordNotFound unless @plaintext_token
  end

  def new
    @token = Doorkeeper::AccessToken.build
  end

  def create
    token_params = params.require(:doorkeeper_access_token).permit(:expires_in, scopes: [])
    @token = @application.access_tokens.create(
      expires_in: token_params[:expires_in].to_i,
      resource_owner_id: @application.owner.id,
      scopes: token_params[:scopes].compact_blank.join(" ")
    )
    if @token&.valid?
      flash[:plaintext_token] = @token.plaintext_token
      redirect_to [@application, @token], notice: t(".success")
    else
      flash.now[:alert] = t(".failed")
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    @token.revoke
    redirect_to @application, notice: t(".success")
  end

  private

  def get_application
    @application = policy_scope(Doorkeeper::Application).find(params[:doorkeeper_application_id])
    authorize @application
  end

  def get_token
    @token = @application.access_tokens.find(params[:id])
    authorize @token
  end
end
