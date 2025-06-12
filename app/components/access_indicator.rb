class Components::AccessIndicator < Components::Base
  def initialize(object:)
    @object = object
  end

  def view_template
    span class: "text-info" do
      if @object.public?
        Icon(icon: "eye", label: t("general.public"))
      end
    end
  end
end
