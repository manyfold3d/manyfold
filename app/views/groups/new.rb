# frozen_string_literal: true

class Views::Groups::New < Views::Groups::Form
  def view_template
    h1 do
      link_to "#{@creator.name} /", @creator, class: "link-secondary link-underline-opacity-0"
      whitespace
      link_to "#{t("views.groups.index.title")} /", creator_groups_path(@creator), class: "link-secondary link-underline-opacity-0"
      whitespace
      span { t("views.groups.new.title") }
    end
    super
  end
end
