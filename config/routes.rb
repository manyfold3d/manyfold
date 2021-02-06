Rails.application.routes.draw do
  resources :libraries, only: [:index, :show] do
    resources :models, only: [:show]
  end
end
