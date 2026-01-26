class DoorkeeperApplicationsController < ApplicationController
  before_action :get_application, except: [:index, :new, :create]

  def index
    @applications = policy_scope(Doorkeeper::Application)
  end

  def show
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
      render :new, layout: "settings", status: :unprocessable_content
    end
  end

  def update
    @application.update(application_params)
    if @application.save
      render :show, notice: t(".success")
    else
      flash.now[:alert] = t(".failure")
      render :edit, layout: "settings", status: :unprocessable_content
    end
  end

  def destroy
    @application.destroy
    redirect_to doorkeeper_applications_path, notice: t(".success")
  end

  private

  def application_params
    params.expect(doorkeeper_application: [
      :name,
      :redirect_uri,
      :confidential,
      scopes: []
    ])
  end

  def get_application
    @application = policy_scope(Doorkeeper::Application).find(params[:id])
    authorize @application
  end
end
