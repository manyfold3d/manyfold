class Components::AltchaWidget < Components::Base
  include Phlex::Rails::Helpers::JavaScriptURL

  register_element :altcha_widget

  def view_template
    div class: "altcha-wrapper" do
      Icon(icon: "robot", label: t("components.altcha_widget.help"))
      altcha_widget(
        id: "altcha-widget",
        auto: "onload",
        challengeurl: altcha_url,
        hidefooter: true,
        hidelogo: true,
        workerurl: javascript_url("altcha_worker.js")
      )
    end
  end
end
