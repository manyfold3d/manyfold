module SettingsHelper
  def masked_email(email)
    email.gsub(/(?<=^.)[^@]*|(?<=@.).*(?=\.[^.]+$)/, "****")
  end

  def model_count(library: nil)
    scope = policy_scope(Model)
    scope = scope.where(library: library) if library
    scope.count
  end

  def model_file_count(library: nil)
    scope = policy_scope(ModelFile)
    scope = scope.includes(:model).where("models.library": library) if library
    scope.count
  end

  def total_file_size(library: nil)
    scope = policy_scope(ModelFile)
    scope = scope.includes(:model).where("models.library": library) if library
    scope.sum(:size)
  end

  def creator_count
    policy_scope(Creator).local.count
  end

  def collection_count
    policy_scope(Collection).local.count
  end

  def tag_count
    policy_scope(ActsAsTaggableOn::Tag).count
  end

  def user_count
    policy_scope(User).count
  end

  def side_menu_link(text, href, icon: nil)
    content_tag(:li, class: "nav-item") do
      parts = if icon
        [
          Icon(icon: icon, label: text),
          content_tag(:span, class: "d-none d-lg-inline") { text }
        ]
      else
        [text]
      end
      link_to(href, class: "nav-link") { safe_join(parts, " ") }
    end
  end
end
