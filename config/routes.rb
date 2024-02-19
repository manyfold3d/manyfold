Rails.application.routes.draw do
  get "problems/index"
  devise_for :users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  resources :users do
    resource :settings, only: [:show, :update]
  end

  root to: "home#index"
  get "images/resize", to: "images#resize", as: "resized_image"
  resources :uploads, only: [:index, :create]
  resources :libraries do
    member do
      post "scan"
    end
    collection do
      post "scan", action: :scan_all
    end
    resources :models, except: [:index] do
      member do
        post "merge"
      end
      resources :model_files, except: [:index] do
        collection do
          get "edit", action: "bulk_edit"
          patch "update", action: "bulk_update"
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
