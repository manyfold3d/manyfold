class DoorkeeperApplicationsController < ApplicationController
  before_action :get_application, except: [:index, :new, :create]

  def index
    @applications = policy_scope(Doorkeeper::Application)
  end

  def show
    get_access_token
  end

  def new
    authorize Doorkeeper::Application
    @application = Doorkeeper::Application.new(
      redirect_uri: "urn:ietf:wg:oauth:2.0:oob",
      scopes: Doorkeeper.configuration.default_scopes
    )
  end

  def edit
  end

  def create
    authorize Doorkeeper::Application
    @application = Doorkeeper::Application.create(application_params.merge(owner: current_user))
    if @application.valid?
      redirect_to @application, notice: t(".success")
    else
      flash.now[:alert] = t(".failure")
      render :new
    end
  end

  def update
    generate_token if application_params[:generate_token]
    @application.update(application_params.except(:generate_token))
    if @application.save
      get_access_token
      render :show, notice: t(".success")
    else
      flash.now[:alert] = t(".failure")
      render :edit
    end
  end

  def destroy
    @application.destroy
    redirect_to doorkeeper_applications_path, notice: t(".success")
  end

  private

  def application_params
    params.require(:doorkeeper_application).permit(
      :name,
      :redirect_uri,
      :confidential,
      :scopes,
      :generate_token
    )
  end

  def get_application
    @application = policy_scope(Doorkeeper::Application).find(params[:id])
    authorize @application
  end

  def generate_token
    # Revoke existing tokens
    Doorkeeper::Application.revoke_tokens_and_grants_for(@application, @application.owner)
    # Create new access token
    token = @application.access_tokens.create(
      expires_in: 6.months,
      resource_owner_id: @application.owner.id,
      scopes: @application.scopes
    )
    # Make plaintext available to view
    @plaintext_token = token.plaintext_token
  end

  def get_access_token
    @access_token = @application.access_tokens.where(revoked_at: nil).first
  end
end
