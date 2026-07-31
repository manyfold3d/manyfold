root to: "application#index"
get "/dashboard", to: "home#index", as: :dashboard
get "/about", to: "home#about", as: :about

get "health" => "rails/health#show", :as => :rails_health_check
resources :benchmark, only: [:index, :create, :destroy] if Amiko.env.development?

# Web crawler stuff
get "/robots", to: "robots#index"
get "/sitemap", to: "robots#sitemap"
