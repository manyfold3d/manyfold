# frozen_string_literal: true

class Components::Comment < Components::Base
  include Phlex::Rails::Helpers::TimeAgoInWords

  register_output_helper :markdownify

  def initialize(comment:, show_system: false)
    @comment = comment
    @show_system = show_system
  end

  def render?
    !@comment.system || @show_system
  end

  def view_template
    div class: "comment-component" do
      div class: "comment-header" do
        if @comment.system
          Icon icon: "robot", label: t("components.comment.system")
        else
          Icon icon: "chat", role: "presentation"
        end
        whitespace
        span { @comment.commenter.try(:name) || @comment.commenter.try(:username) }
        whitespace
        span(class: "comment-time", title: @comment.created_at) { t("components.comment.posted", time: time_ago_in_words(@comment.created_at)) }
      end
      div(class: "comment-body") { markdownify(@comment.comment) }
    end
  end
end
