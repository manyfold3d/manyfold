if SiteSettings.social_enabled? || Amiko.env.test?
  authenticate :user do
    resources :follows, only: [:index, :new]
  end
end
