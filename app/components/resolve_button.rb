# frozen_string_literal: true

class Components::ResolveButton < Components::Base
  include Phlex::Rails::Helpers::LinkTo

  OPTIONS = {
    show: {
      icon: "box",
      i18n_key: "models.file.open_button.text", # i18n-tasks-use t('models.file.open_button.text')
      button_type: "primary"
    },
    edit: {
      icon: "pencil",
      i18n_key: "general.edit", # i18n-tasks-use t('general.edit')
      button_type: "primary"
    },
    destroy: {
      icon: "trash",
      i18n_key: "general.delete", # i18n-tasks-use t('general.delete')
      button_type: "danger",
      confirm: "%{type}s.destroy.confirm"
    },
    merge: {
      icon: "box-arrow-in-up-left",
      i18n_key: "models.problem.merge_all", # i18n-tasks-use t('models.problem.merge_all')
      button_type: "danger"
    },
    upload: {
      icon: "upload",
      i18n_key: "application.navbar.upload", # i18n-tasks-use t('application.navbar.upload')
      button_type: "primary"
    },
    convert: {
      icon: "arrow-left-right",
      i18n_key: "model_files.show.convert", # i18n-tasks-use t('model_files.show.convert')
      button_type: "warning"
    }
  }

  def initialize(problem:, user: nil)
    @problem = problem
    @user = user
  end

  def before_template
    @options = OPTIONS[@problem.resolution_strategy.to_sym]
  end

  def view_template
    return unless render?
    text = t @options[:i18n_key]
    if @problem.in_progress
      link_to("#", class: "btn btn-#{@options[:button_type]} disabled") do
        span(class: "spinner-border spinner-border-sm") { icon("", "") }
        whitespace
        span { text }
      end
    else
      link_to(
        resolve_problem_path(@problem),
        class: "btn btn-#{@options[:button_type]}",
        data: {
          confirm: @options[:confirm] ?
            translate(@options[:confirm] % {type: @problem.problematic_type.underscore}) :
            nil
        },
        method: :post
      ) do
        icon(@options[:icon], text)
        whitespace
        span { text }
      end
    end
  end

  private

  def render?
    ProblemPolicy.new(@user, @problem).resolve?
  end
end
