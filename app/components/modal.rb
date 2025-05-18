class Components::Modal < Components::Base
  def initialize(id:, title:)
    @id = id
    @title = title
  end

  def view_template
    div class: "modal fade modal-lg", id: @id, tabindex: "-1", "aria-labelledby": "#{@id}-label", "aria-hidden": "true" do
      div class: "modal-dialog" do
        div class: "modal-content" do
          div class: "modal-header" do
            h1(class: "modal-title fs-5", id: "#{@id}-label") { @title }
            button type: "button", class: "btn-close", "data-bs-dismiss": "modal", "aria-label": t("components.modal.close")
          end
          div class: "modal-body" do
            yield
          end
        end
      end
    end
  end
end
