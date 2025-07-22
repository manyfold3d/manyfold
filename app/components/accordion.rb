class Components::Accordion < Components::Base
  def initialize(title:, open: false, id: SecureRandom.uuid)
    @title = title
    @open = open
    @id = id
  end

  def view_template
    div class: "accordion accordion-flush mb-2" do
      div class: "accordion-item" do
        h3 class: "accordion-header" do
          button class: "accordion-button #{"collapsed" unless @open}", type: "button", data: {bs_toggle: "collapse", bs_target: "##{@id}"}, aria: {controls: @id} do
            @title
          end
        end
      end
      div id: @id, class: "accordion-collapse collapse #{"show" if @open}" do
        div class: "accordion-body" do
          yield
        end
      end
    end
  end
end
