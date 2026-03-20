# frozen_string_literal: true

class Components::Comment < Components::Base
  include Phlex::Rails::Helpers::TimeAgoInWords
  include Phlex::Rails::Helpers::LinkTo

  register_output_helper :markdownify

  def initialize(comment:, show_system: false)
    @comment = comment
    @show_system = show_system
  end

  def render?
    !@comment.system || @show_system
  end

  def before_template
    @reported = @comment.reports.any?
  end

  def view_template
    div class: "comment-component #{"comment-reported" if @reported}" do
      div class: "comment-header" do
        div do
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
        div class: "comment-header-links" do
          link_to polymorphic_path([@comment.commentable, @comment, :report], action: :new) do
            Icon(icon: "flag", label: t("components.comment.report"))
          end
          whitespace
          if policy(@comment).destroy?
            span(class: "ms-2") do
              link_to [@comment.commentable, @comment], method: :delete, class: "link-danger", data: {confirm: t("components.comment.confirm_delete")} do
                Icon(icon: "trash", label: t("components.comment.delete"))
              end
            end
          end
        end
      end
      div(class: "comment-body") { markdownify(@comment.comment) }
      if current_user.is_moderator? && @comment.reports.any?
        div(class: "comment-footer comment-footer-reported") do
          span { t("components.comment.reported", time: @comment.reports.order(created_at: :desc).pick(:created_at)) }
        end
      end
    end
  end
end
