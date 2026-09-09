# frozen_string_literal: true

class Components::ResolveButton < Components::Base
  include Phlex::Rails::Helpers::ButtonTo

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
      button_type: "outline-danger",
      confirm: "%{type}s.destroy.confirm"
    },
    merge: {
      icon: "box-arrow-in-up-left",
      i18n_key: "models.problem.merge_all", # i18n-tasks-use t('models.problem.merge_all')
      button_type: "success"
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
    },
    organize: {
      icon: "folder-check",
      i18n_key: "models.organize.label", # i18n-tasks-use t('models.organize.label')
      button_type: "warning",
      confirm: "models.organize.confirm" # i18n-tasks-use t('models.organize.confirm')
    }
  }

  def initialize(problem:, user: nil, from_model: nil)
    @problem = problem
    @user = user
    @from_model = from_model
  end

  def before_template
    @options = OPTIONS[@problem.resolution_strategy.to_sym]
    @text = t @options[:i18n_key]
  end

  def resolve_url
    opts = {resolve: true, format: :turbo_stream}
    opts[:from] = "model" if @from_model
    opts[:model_id] = @from_model.public_id if @from_model
    resolve_problem_path(@problem, opts)
  end

  def view_template
    if @problem.in_progress || @problem.resolving?
      disabled_class = [Components::BaseButton::BASE_CLASSES, resolve_button_variant_class, "opacity-70 cursor-not-allowed"].join(" ")
      button_to("#", class: disabled_class, disabled: true) do
        span(class: "animate-spin inline-block w-4 h-4 border-2 border-current border-t-transparent rounded-full") { "" }
        whitespace
        span { @text }
      end
    else
      DoButton(
        label: @text,
        href: resolve_url,
        variant: @options[:button_type],
        icon: @options[:icon],
        method: :post,
        confirm: @options[:confirm] ? translate(@options[:confirm] % {type: @problem.problematic_type.underscore}) : nil,
        nofollow: true
      )
    end
  end

  def render?
    ProblemPolicy.new(@user, @problem).resolve?
  end

  private

  def resolve_button_variant_class
    Components::BaseButton::VARIANT_CLASSES[@options[:button_type]] || Components::BaseButton::VARIANT_CLASSES["primary"]
  end
end
