# frozen_string_literal: true

# INIT-013/SPEC-004 — dark monitoring sidebar (~240px) for performance dashboard.
class Components::Performance::Sidebar < Components::Base
  NAV_ITEMS = [
    {key: :dashboard, icon: "house", href: :self, active: true},
    {key: :requests_analysis, icon: "graph-up", href: :rails_performance},
    {key: :recent_requests, icon: "clock-history", href: :rails_performance},
    {key: :system, icon: "cpu", href: :rails_performance},
    {key: :slow_requests, icon: "exclamation-circle", href: :rails_performance},
    {key: :errors_500, icon: "shield-exclamation", href: :rails_performance},
    {key: :sidekiq, icon: "database", href: :sidekiq},
    {key: :custom_events, icon: "lightning", href: :hash}
  ].freeze

  def view_template
    aside(
      class: "w-60 shrink-0 bg-secondary-900 text-secondary-100 flex flex-col gap-6 px-4 py-6 border-r border-secondary-800 min-h-[32rem]",
      data: {region: "performance-sidebar"},
      aria: {label: t("performance.index.sidebar.nav_label")}
    ) do
      brand
      nav(class: "flex flex-col gap-1 flex-1") do
        NAV_ITEMS.each { |item| nav_item(item) }
      end
      footer
    end
  end

  private

  def brand
    div(class: "flex items-center gap-2.5 px-2") do
      div(class: "size-8 rounded-lg bg-danger flex items-center justify-center shrink-0") do
        Icon(icon: "x-circle", label: nil, role: "presentation")
      end
      div(class: "flex flex-col gap-0.5 min-w-0") do
        p(class: "text-[15px] font-bold text-secondary-50 m-0 leading-tight") { t("performance.index.sidebar.brand") }
        p(class: "text-[11px] font-medium uppercase tracking-wide text-secondary-400 m-0") { t("performance.index.sidebar.monitoring") }
      end
    end
  end

  def nav_item(item)
    href = resolve_href(item[:href])
    active = item[:active]
    classes = if active
      "bg-secondary-800 text-secondary-50 font-medium"
    else
      "text-secondary-400 hover:bg-secondary-800/60 hover:text-secondary-100"
    end

    a(
      href: href,
      class: "flex items-center gap-3 px-4 py-2.5 rounded-lg text-sm no-underline #{classes}",
      aria: (active ? {current: "page"} : {})
    ) do
      span(class: "shrink-0 text-base leading-none") { Icon(icon: item[:icon], role: "presentation") }
      span(class: "flex-1 min-w-0") { t("performance.index.sidebar.nav.#{item[:key]}") } # rubocop:todo I18n/RailsI18n/DecorateStringFormattingUsingInterpolation
      if active
        span(class: "w-1 h-4 rounded-sm bg-primary-500 shrink-0", "aria-hidden": "true")
      end
    end
  end

  def resolve_href(kind)
    case kind
    when :self
      admin_performance_path
    when :sidekiq
      sidekiq_web_path
    when :rails_performance
      # Gem engine is not mounted in test; P1 stubs may use the escape-hatch path.
      "/admin/rails_performance"
    else
      "#"
    end
  end

  def footer
    div(class: "mt-auto flex flex-col gap-1.5 px-2") do
      span(class: "inline-flex w-fit items-center gap-1.5 rounded-md bg-success/15 px-2 py-1 text-[11px] font-semibold uppercase tracking-wide text-success") do
        span(class: "size-1.5 rounded-full bg-success", "aria-hidden": "true")
        plain env_label
      end
      p(class: "text-[11px] text-secondary-400 m-0") { version_label }
    end
  end

  def env_label
    case Rails.env
    when "production" then t("performance.index.sidebar.env.production")
    when "development" then t("performance.index.sidebar.env.development")
    when "staging" then t("performance.index.sidebar.env.staging")
    when "test" then t("performance.index.sidebar.env.test")
    else Rails.env.upcase
    end
  end

  def version_label
    app = Rails.application.config.try(:app_version).presence || Rails.version
    t("performance.index.sidebar.version", app: app, ruby: RUBY_VERSION)
  end
end
