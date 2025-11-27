# frozen_string_literal: true

class Components::ActorCard < Components::ModelCard
  def initialize(actor:)
    @actor = actor
  end

  def before_template
  end

  def view_template
    div class: "col col-3 mb-4" do
      div class: "card preview-card" do
        div(class: "card-header position-absolute w-100 top-0 z-3 bg-body-secondary text-secondary-emphasis opacity-75") do
          server_indicator @actor, full_address: true
        end
        PreviewFrame(object: @actor)
        div(class: "card-body") { info_row }
        actions
      end
    end
  end

  private

  def f3di_icon_for(concrete_type)
    case concrete_type
    when "Creator"
      "person"
    when "Collection"
      "collection"
    when "Model"
      "box"
    end
  end

  def title
    div class: "card-title" do
      icon = f3di_icon_for(@actor.extensions&.dig("f3di:concreteType"))
      icon ? Icon(icon: icon) : span { "⁂" }
      whitespace
      span { sanitize(@actor.name) }
    end
  end

  def actions
    div class: "card-footer" do
      div class: "row" do
        div class: "col" do
          FollowButton(follower: current_user, target: @actor)
          if !@actor.local? && @actor.extensions&.dig("f3di:concreteType").nil?
            span class: "text-warning ms-2" do
              Icon(icon: "exclamation-triangle-fill", label: translate("components.actor_card.non_manyfold_account"))
              t("components.actor_card.non_manyfold_account")
            end
          end
        end
        div class: "col col-auto" do
          open_button
        end
      end
    end
  end
end
