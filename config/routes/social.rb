if SiteSettings.social_enabled? || Rails.env.test?
  resources :follows, only: [:index, :new]
end
