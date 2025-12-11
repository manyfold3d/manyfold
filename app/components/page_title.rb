# frozen_string_literal: true

class Components::PageTitle < Components::Base
  def initialize(title:, breadcrumbs: {}, heading: true)
    @title = title
    @breadcrumbs = breadcrumbs
    @heading = heading
  end

  def view_template
    nav aria: {label: "breadcrumb"} do
      ol class: "breadcrumb" do
        li class: "breadcrumb-item" do
          a(href: root_url) { Icon icon: "house", label: t("application.navbar.home") }
        end
        @breadcrumbs.map do |text, path|
          li class: "breadcrumb-item" do
            a(href: path) { text }
          end
        end
        li(class: "breadcrumb-item active", aria: {current: "page"}) { @title }
      end
    end
    hr
    if @heading
      h1 do
        span { @title }
      end
    end
  end
end
