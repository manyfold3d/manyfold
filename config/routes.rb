Rails.application.routes.draw do
  root to: "libraries#index"
  resources :libraries, only: [:index, :show] do
    resources :models, only: [:show] do
      resources :parts, only: [:show]
    end
  end
end
