if SiteSettings.social_enabled? || Rails.env.test?
  authenticate :user do
    resources :follows, only: [:index, :new]
  end
end
