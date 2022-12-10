Rails.application.routes.draw do
  get "problems/index"
  devise_for :users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  resources :users do
    resource :settings, only: [:show, :update]
  end

  root to: "search#index"
  post "/", controller: :search, action: :index

  resources :libraries do
    resources :models, except: [:index, :destroy] do
      member do
        post "merge"
      end
      collection do
        get "edit", action: "bulk_edit"
        patch "update", action: "bulk_update"
      end
      resources :model_files, except: [:index] do
        collection do
          get "edit", action: "bulk_edit"
          patch "update", action: "bulk_update"
        end
      end
    end
  end
  resources :creators
  resources :collections, only: [:index, :show]
  resources :problems, only: [:index]
end
