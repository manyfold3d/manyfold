# frozen_string_literal: true

class Components::NewCommentForm < Components::Base
  include Phlex::Rails::Helpers::FormFor

  register_value_helper :policy

  def initialize(commentable:)
    @commentable = commentable
    @comment = @commentable.comments.new
  end

  def render?
    policy(@comment).create?
  end

  def view_template
    form_for [@commentable, @comment] do |f|
      div class: "new-comment-form-component", name: "new-comment" do
        div(class: "comment-header") do
          div do
            Icon(icon: "pen")
            whitespace
            span { t("components.new_comment_form.title") }
          end
        end
        div(class: "comment-body") do
          f.text_area(:comment, class: "form-control", placeholder: translate("components.new_comment_form.placeholder"))
        end
        div(class: "comment-footer") do
          f.submit t("components.new_comment_form.submit")
        end
      end
    end
  end
end
