Rails.application.routes.draw do
  get "problems/index"
  devise_for :users, controllers: {
    passwords: "users/passwords",
    registrations: "users/registrations",
    sessions: "users/sessions"
  }

  ActiveAdmin.routes(self)

  resources :users, only: [] do
    resource :settings, only: [:show, :update]
  end

  root to: "home#index"

  resources :uploads, only: [:index, :create]
  resources :libraries do
    member do
      post "scan"
    end
    collection do
      post "scan", action: :scan_all
    end
    resources :models, except: [:index, :new, :create] do
      member do
        post "merge"
        post "scan"
      end
      resources :model_files, except: [:index, :new] do
        collection do
          get "bulk_edit"
          patch "bulk_update"
        end
      end
    end
  end
  resources :models, only: [:index] do
    collection do
      get "edit", action: "bulk_edit"
      patch "/update", action: "bulk_update"
    end
  end
  resources :creators
  resources :collections
  resources :problems, only: [:index, :update]
end
