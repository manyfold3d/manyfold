Rails.application.config.after_initialize do
  if Rails.env.development?
    Bullet.enable = true
    Bullet.rails_logger = true

    # Features
    Bullet.n_plus_one_query_enable = true
    Bullet.unused_eager_loading_enable = true
    Bullet.counter_cache_enable = false
  end
end
