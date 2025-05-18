class Components::SearchHelp < Components::Base
  def view_template
    div class: "text-start" do
      a "data-bs-toggle": "modal", "data-bs-target": "#search-help" do
        yield
      end

      render Components::Modal.new(id: "search-help", title: t(".title")) do
        p do
          t(".intro")
        end
        table class: "table table-striped" do
          tr do
            td { code { "cat hat" } }
            td { t(".simple") }
          end
          tr do
            td { code { "cat or hat" } }
            td { t(".boolean") }
          end
          tr do
            td do
              code { "cat -hat" }
              br
              code { "cat !hat" }
              br
              code { "cat not hat" }
            end
            td { t(".negation") }
          end
          tr do
            td { code { '"cat hat"' } }
            td { t(".quotes") }
          end
          tr do
            td { code { "(cat or hat) and not bat" } }
            td { t(".parentheses") }
          end
          tr do
            td do
              code { "tag = cat" }
            end
            td { t(".tag") }
          end
          tr do
            td do
              code { "tag != cat" }
            end
            td { t(".without_tag") }
          end
          tr do
            td do
              code { "notes ~ cat" }
              br
              code { "caption ~ cat" }
              br
              code { "creator ~ cat" }
              br
              code { "collection ~ cat" }
            end
            td { t(".specific_fields") }
          end
          tr do
            td do
              code { "not set? tag" }
            end
            td { t(".unset") }
          end
          tr do
            td do
              code { "filename = cat.stl" }
            end
            td { t(".filename") }
          end
        end
        p do
          t(".more_details_html")
        end
      end
    end
  end
end
