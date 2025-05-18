class Components::SearchHelp < Components::Base
  def view_template
    div class: "text-start" do
      a "data-bs-toggle": "modal", "data-bs-target": "#search-help" do
        yield
      end

      render Components::Modal.new(id: "search-help", title: t("components.search_help.title")) do
        p do
          t("components.search_help.intro")
        end
        table class: "table table-striped" do
          tr do
            td { code { "cat hat" } }
            td { t("components.search_help.simple") }
          end
          tr do
            td { code { "cat or hat" } }
            td { t("components.search_help.boolean") }
          end
          tr do
            td do
              code { "cat -hat" }
              br
              code { "cat !hat" }
              br
              code { "cat not hat" }
            end
            td { t("components.search_help.negation") }
          end
          tr do
            td { code { '"cat hat"' } }
            td { t("components.search_help.quotes") }
          end
          tr do
            td { code { "(cat or hat) and not bat" } }
            td { t("components.search_help.parentheses") }
          end
          tr do
            td do
              code { "tag = cat" }
            end
            td { t("components.search_help.tag") }
          end
          tr do
            td do
              code { "tag != cat" }
            end
            td { t("components.search_help.without_tag") }
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
            td { t("components.search_help.specific_fields") }
          end
          tr do
            td do
              code { "not set? tag" }
            end
            td { t("components.search_help.unset") }
          end
          tr do
            td do
              code { "filename = cat.stl" }
            end
            td { t("components.search_help.filename") }
          end
        end
        p do
          t("components.search_help.more_details_html")
        end
      end
    end
  end
end
