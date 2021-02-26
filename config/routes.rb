Rails.application.routes.draw do
  root to: "libraries#index"
  resources :libraries, only: [:index, :show, :new, :create, :update] do
    resources :models, only: [:show, :update] do
      resources :parts, only: [:show, :update]
    end
  end
  resources :creators
end
