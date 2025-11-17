require "sidekiq/web"
require "sidekiq/cron/web"
require "federails"

Rails.application.routes.draw do
  get "/altcha", to: "altcha#new"
  get ".well-known/change-password", to: redirect("/users/edit")
  get "health" => "rails/health#show", :as => :rails_health_check
  get "problems/index"

  devise_controllers = {
    passwords: "users/passwords",
    registrations: "users/registrations",
    sessions: "users/sessions"
  }
  devise_controllers[:omniauth_callbacks] = "users/omniauth_callbacks" if Rails.application.config.manyfold_features[:oidc]
  devise_for :users, controllers: devise_controllers

  authenticate :user, lambda { |u| u.is_administrator? } do
    resource :settings, only: [:show, :update] do
      collection do
        get :analysis
        get :downloads
        get :multiuser
        get :reporting
        get :appearance
        get :discovery
        get :integrations
      end
      resources :libraries, only: [:index]
    end
    mount Sidekiq::Web => "/admin/sidekiq"
    mount RailsPerformance::Engine => "/admin/performance" unless Rails.env.test? || ENV["RAILS_ASSETS_PRECOMPILE"].present?
    mount PgHero::Engine => "/admin/pghero"
    get "/activity" => "activity#index", :as => :activity
  end

  if SiteSettings.multiuser_enabled? || Rails.env.test?
    authenticate :user, lambda { |u| u.is_moderator? } do
      namespace :settings do
        resources :users
        resources :reports
      end
    end
    if SiteSettings.federation_enabled? || Rails.env.test?
      mount Federails::Engine => "/"
      mount FaspClient::Engine => "/fasp"
    end

    resources :follows, only: [:index, :new]
    get "/authorize_interaction" => "follows#new" # for compatibility with Mastodon, which assumes this URL

    post "/remote_follow" => "follows#remote_follow", :as => :remote_follow
    post "/perform_remote_follow" => "follows#perform_remote_follow", :as => :perform_remote_follow
    post "/follow_remote_actor/:id" => "follows#follow_remote_actor", :as => :follow_remote_actor
    delete "/follow_remote_actor/:id" => "follows#unfollow_remote_actor", :as => :unfollow_remote_actor
  end

  if SiteSettings.federation_enabled? || Rails.env.test?
    authenticate :user, lambda { |u| u.is_moderator? } do
      namespace :settings do
        resources :domain_blocks if SiteSettings.federation_enabled?
      end
    end
  end

  root to: "home#index"
  get "/about", to: "home#about", as: :about
  resources :imports, only: [:new, :create]
  resources :scans, only: [:create]

  authenticate :user do
    get "/welcome", to: "home#welcome", as: :welcome
  end

  resources :libraries, except: [:index]

  concern :followable do |options|
    if SiteSettings.multiuser_enabled?
      resources :follows, {only: [:create]}.merge(options) do
        collection do
          delete "/", action: "destroy"
        end
      end
    end
  end

  concern :commentable do |options|
    resources :comments, {only: [:show]}.merge(options)
  end
  concern :reportable do |options|
    resources :reports, {only: [:new, :create]}.merge(options)
  end
  concern :linkable do
    member do
      post :sync
    end
  end

  resources :models do
    concerns :followable, followable_class: "Model"
    concerns :commentable, commentable_class: "Model"
    concerns :reportable, reportable_class: "Model"
    concerns :linkable
    member do
      post "scan"
    end
    collection do
      post "merge"
      get "merge", action: "configure_merge", as: "configure_merge"
      get "edit", action: "bulk_edit"
      patch "/update", action: "bulk_update"
    end
    resources :model_files, except: [:index, :new] do
      collection do
        get "bulk_edit"
        patch "bulk_update"
      end
    end
  end
  resources :creators do
    concerns :followable, followable_class: "Creator"
    concerns :commentable, commentable_class: "Creator"
    concerns :reportable, reportable_class: "Creator"
    concerns :linkable
    member do
      get :avatar
      get :banner
    end
  end
  resources :collections do
    concerns :followable, followable_class: "Collection"
    concerns :commentable, commentable_class: "Collection"
    concerns :reportable, reportable_class: "Collection"
    concerns :linkable
  end
  resources :problems, only: [:index, :update] do
    collection do
      post "resolve", action: "resolve"
    end
    member do
      post "resolve"
    end
  end
  resources :benchmark, only: [:index, :create, :destroy] if Rails.env.development?

  authenticate :user, lambda { |u| u.is_contributor? } do
    mount Tus::Server => "/upload", :as => :upload
  end

  get("/oembed", to: redirect(status: 303) { |_, request|
    path = URI.parse(request.params[:url])&.path
    raise ActionController::BadRequest if path.blank?
    URI::HTTP.build(path: path + ".oembed", query: {
      maxwidth: request.params[:maxwidth],
      maxheight: request.params[:maxheight]
    }.compact.to_query)
  })

  mount Rswag::Ui::Engine => "/api", :as => :api
  mount Rswag::Api::Engine => "/api"

  use_doorkeeper do
    skip_controllers :applications
  end
  resources :doorkeeper_applications, path: "/oauth/applications"

  # Fallback routes for filename matching and signed downloads
  get "/models/:model_id/model_files/signed/:sig/*id" => "model_files#show", :as => "model_model_file_by_signed_filename"
  get "/models/:model_id/model_files/*id" => "model_files#show", :as => "model_model_file_by_filename"

  # Web crawler stuff
  get "/robots", to: "robots#index"
  get "/sitemap", to: "robots#sitemap"
end
