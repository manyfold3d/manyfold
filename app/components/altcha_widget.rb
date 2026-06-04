class Components::AltchaWidget < Components::Base
  include Phlex::Rails::Helpers::JavaScriptURL

  register_element :altcha_widget

  def view_template
    altcha_widget(
      id: "altcha-widget",
      auto: "onload",
      challenge: Altcha.create_challenge.to_json
    )
  end
end
