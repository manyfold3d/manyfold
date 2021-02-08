Rails.application.routes.draw do
  resources :libraries, only: [:index, :show] do
    resources :models, only: [:show] do
      resources :parts, only: [:show]
    end
  end
end
