if SiteSettings.social_enabled? || Mosscap.env.test?
  authenticate :user do
    resources :follows, only: [:index, :new]
  end
end
