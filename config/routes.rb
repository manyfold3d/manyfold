require "sidekiq/web"
require "sidekiq/cron/web"
require "federails"

Rails.application.routes.draw do
  draw(:auth)
  draw(:meta)
  draw(:admin)
  draw(:moderation)
  draw(:social)
  draw(:federation)
  draw(:oauth)
  draw(:oembed)
  draw(:upload)
  draw(:api)

  resources :libraries, except: [:index] do
    collection do
      get :preview
    end
    member do
      get :preview
    end
  end

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
    resources :comments, {only: [:show, :create, :destroy]}.merge(options) do
      concerns :reportable, reportable_class: "Comment"
    end
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

  # Fallback routes for filename matching and signed downloads
  get "/models/:model_id/model_files/signed/:sig/*id" => "model_files#show", :as => "model_model_file_by_signed_filename"
  get "/models/:model_id/raw/*filename" => "model_files#raw", :as => "model_model_file_raw"

  resources :creators do
    concerns :followable, followable_class: "Creator"
    concerns :commentable, commentable_class: "Creator"
    concerns :reportable, reportable_class: "Creator"
    concerns :linkable
    member do
      get :avatar
      get :banner
    end
    resources :groups
  end
  resources :collections do
    concerns :followable, followable_class: "Collection"
    concerns :commentable, commentable_class: "Collection"
    concerns :reportable, reportable_class: "Collection"
    concerns :linkable
    member do
      get :cover
    end
  end
  resources :problems, only: [:index, :update] do
    collection do
      post "resolve", action: "resolve"
    end
    member do
      post "resolve"
    end
  end

  authenticate :user do
    get "/welcome", to: "home#welcome", as: :welcome
    resources :lists
    resources :imports, only: [:new, :create]
    resources :scans, only: [:create]
  end
end
