class Components::AccessIndicator < Components::Base
  # @param object The object to show the access details for; must include the CaberSubject concern
  # @param icon Whether or not to show an indicator icon
  # @param text Whether or not to show a indicator text
  def initialize(object:, icon: true, text: false)
    @object = object
    @icon = icon
    @text = text
  end

  def render?
    SiteSettings.multiuser_enabled? && !@object.remote? && (current_user&.is_moderator? || current_user&.has_permission_on?("own", @object))
  end

  def view_template
    span do
      if @object.private?
        span(class: "text-danger") { Icon(icon: "lock-fill", label: t("general.private")) } if @icon
        if @text
          whitespace
          span { t("general.private") }
        end
      elsif @object.public?
        span(class: "text-success") { Icon(icon: "eye-fill", label: t("general.public")) } if @icon
        if @text
          whitespace
          span { t("general.public") }
        end
      else
        span(class: "text-info") { Icon(icon: "unlock", label: t("general.shared")) } if @icon
        if @text
          whitespace
          span { t("general.shared") }
        end
      end
    end
  end
end
