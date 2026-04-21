root to: "home#index"
get "/about", to: "home#about", as: :about

get "health" => "rails/health#show", :as => :rails_health_check
resources :benchmark, only: [:index, :create, :destroy] if Rails.env.development?

# Web crawler stuff
get "/robots", to: "robots#index"
get "/sitemap", to: "robots#sitemap"
