authenticate :user, lambda { |u| u.is_administrator? } do
  resource :settings, only: [:show, :update] do
    collection do
      get :analysis
      get :derivatives
      get :multiuser
      get :reporting
      get :appearance
      get :discovery
      get :integrations
    end
    resources :libraries, only: [:index]
  end
  mount Sidekiq::Web => "/admin/sidekiq"
  mount RailsPerformance::Engine => "/admin/performance" unless Rails.env.test? || ENV["RAILS_ASSETS_PRECOMPILE"].present?
  mount PgHero::Engine => "/admin/pghero" if defined?(PgHero)
  get "/activity" => "activity#index", :as => :activity
end
