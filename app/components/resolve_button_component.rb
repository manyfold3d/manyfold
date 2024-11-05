# frozen_string_literal: true

class ResolveButtonComponent < ViewComponent::Base
  OPTIONS = {
    show: {
      icon: "box",
      i18n_key: "models.file.open_button.text",
      button_type: "primary"
    },
    edit: {
      icon: "pencil",
      i18n_key: "general.edit",
      button_type: "primary"
    },
    destroy: {
      icon: "trash",
      i18n_key: "general.delete",
      button_type: "danger",
      confirm: "%{type}s.destroy.confirm"
    },
    merge: {
      icon: "box-arrow-in-up-left",
      i18n_key: "models.problem.merge_all",
      button_type: "danger"
    },
    upload: {
      icon: "upload",
      i18n_key: "application.navbar.upload",
      button_type: "primary"
    },
    convert: {
      icon: "arrow-left-right",
      i18n_key: "model_files.show.convert",
      button_type: "warning"
    }
  }

  def initialize(problem:, user: nil)
    @problem = problem
    @user = user
  end

  def before_render
    @options = OPTIONS[@problem.resolution_strategy.to_sym]
  end

  def render?
    ProblemPolicy.new(@user, @problem).resolve?
  end

  def call
    text = t @options[:i18n_key]
    if @problem.in_progress
      link_to(
        safe_join(
          [
            content_tag(:span, helpers.icon("", ""), class: "spinner-border spinner-border-sm"),
            content_tag(:span, text)
          ],
          " "
        ),
        "#",
        class: "btn btn-#{@options[:button_type]} disabled"
      )
    else
      link_to(
        safe_join([helpers.icon(@options[:icon], text), text], " "),
        resolve_problem_path(@problem),
        class: "btn btn-#{@options[:button_type]}",
        data: {
          confirm: @options[:confirm] ?
            translate(@options[:confirm] % {type: @problem.problematic_type.underscore}) :
            nil
        },
        method: :post
      )
    end
  end
end
