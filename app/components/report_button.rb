# frozen_string_literal: true

class Components::ReportButton < Components::Base
  def initialize(object:, path:)
    @object = object
    @path = path
  end

  def view_template
    GoButton(
      icon: "flag",
      href: @path,
      label: t("general.report", type: @object.model_name.human),
      variant: "outline-warning"
    )
  end

  def render?
    SiteSettings.multiuser_enabled?
  end
end
