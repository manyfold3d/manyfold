require "sidekiq/web"
require "sidekiq/cron/web"
require "federails"

Rails.application.routes.draw do
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

  ActiveAdmin.routes(self)
  authenticate :user, lambda { |u| u.is_administrator? } do
    mount Sidekiq::Web => "/admin/sidekiq"
    mount RailsPerformance::Engine => "/admin/performance" unless Rails.env.test?
    mount PgHero::Engine => "/admin/pghero"
    resources :activity
  end

  mount Federails::Engine => "/" if SiteSettings.multiuser_enabled? || SiteSettings.federation_enabled? || Rails.env.test?

  resources :users, only: [] do
    resource :settings, only: [:show, :update]
  end

  root to: "home#index"

  resources :libraries do
    member do
      post "scan"
    end
    collection do
      post "scan", action: :scan_all
    end
  end

  get "/follow" => "follows#index", :as => :follow
  get "/authorize_interaction" => "follows#new", :as => :new_follow
  post "/remote_follow" => "follows#remote_follow", :as => :remote_follow
  post "/perform_remote_follow" => "follows#perform_remote_follow", :as => :perform_remote_follow
  post "/follow_remote_actor/:id" => "follows#follow_remote_actor", :as => :follow_remote_actor

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

  resources :models do
    concerns :followable, followable_class: "Model"
    concerns :commentable, commentable_class: "Model"
    member do
      post "merge"
      post "scan"
    end
    collection do
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
  end
  resources :collections do
    concerns :followable, followable_class: "Collection"
    concerns :commentable, commentable_class: "Collection"
  end
  resources :problems, only: [:index, :update]
  resources :benchmark, only: [:index, :create, :destroy] if Rails.env.development?

  authenticate :user, lambda { |u| u.is_contributor? } do
    mount LibraryUploader.upload_endpoint(:cache) => "/upload"
  end
end
