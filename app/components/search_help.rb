class Components::SearchHelp < Components::Base
  def view_template
    div class: "text-start" do
      a class: "link-underline link-underline-opacity-0",
        aria: {
          haspopup: true
        },
        data: {
          bs_toggle: "modal",
          bs_target: "#search-help"
        }, tabindex: 0, href: "#" do
        yield
      end
      modal
    end
  end

  def modal
    Modal(id: "search-help", title: t("components.search_help.title")) do
      p do
        t("components.search_help.intro")
      end
      help_table
      p do
        t("components.search_help.more_details_html")
      end
    end
  end

  def help_table
    table class: "table table-striped" do
      tr do
        td { code { "cat hat" } }
        td { t("components.search_help.simple") }
      end
      tr do
        td { code { "cat or hat" } }
        td { t("components.search_help.boolean") }
      end
      negation
      tr do
        td { code { '"cat hat"' } }
        td { t("components.search_help.quotes") }
      end
      tr do
        td { code { "(cat or hat) and not bat" } }
        td { t("components.search_help.parentheses") }
      end
      tr do
        td { code { "tag = cat" } }
        td { t("components.search_help.tag") }
      end
      tr do
        td { code { "tag != cat" } }
        td { t("components.search_help.without_tag") }
      end
      specific_fields
      tr do
        td { code { "not set? tag" } }
        td { t("components.search_help.unset") }
      end
      path
      filenames
      federation
    end
  end

  def path
    tr do
      td do
        code { "path ~ tools" }
      end
      td { t("components.search_help.path") }
    end
  end

  def filenames
    tr do
      td do
        code { "filename = cat.stl" }
        br
        code { "filename ~ cat" }
      end
      td { t("components.search_help.filename") }
    end
  end

  def specific_fields
    tr do
      td do
        code { "creator ~ cat" }
        br
        code { "collection ~ cat" }
        br
        code { "caption ~ cat" }
        br
        code { "description ~ cat" }
        if SiteSettings.show_libraries?
          br
          code { "library = #{Library.first.name}" }
        end
      end
      td { t("components.search_help.specific_fields") }
    end
  end

  def negation
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
  end

  def federation
    return unless SiteSettings.federation_enabled?
    tr do
      td do
        code { "@manyfold@3dp.chat" }
      end
      td { t("components.search_help.federation") }
    end
  end
end
