Rails.application.routes.draw do
  resources :libraries, only: [:index, :show]
end
