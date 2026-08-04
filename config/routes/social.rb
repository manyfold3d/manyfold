if SiteSettings.social_enabled? || Amiko.env.test?
  resources :follows, only: [:index, :new]
end
