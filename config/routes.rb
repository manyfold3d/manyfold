require "sidekiq/web"
require "sidekiq-scheduler/web"

Rails.application.routes.draw do
  get ".well-known/change-password", to: redirect("/users/edit")

  get "problems/index"
  devise_for :users, controllers: {
    passwords: "users/passwords",
    registrations: "users/registrations",
    sessions: "users/sessions"
  }

  ActiveAdmin.routes(self)
  authenticate :user, lambda { |u| u.is_administrator? } do
    mount Sidekiq::Web => "/sidekiq"
    resources :activity
  end

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
  resources :models do
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
  resources :creators
  resources :collections
  resources :problems, only: [:index, :update]
  resources :health, only: [:index]

  authenticate :user, lambda { |u| u.is_contributor? } do
    mount LibraryUploader.upload_endpoint(:cache) => "/upload"
  end
end
