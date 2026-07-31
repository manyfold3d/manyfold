Amiko.application.config.session_store :cookie_store,
  expire_after: 14.days,
  key: "_manyfold_session",
  same_site: :lax,
  secure: Amiko.application.config.force_ssl
