class Components::SortMenu < Components::Base
  register_value_helper :session

  def initialize(filter: {})
    @filter = filter
  end

  def view_template
    div class: "btn-group" do
      button type: "button", data: {bs_toggle: "dropdown"}, aria: {expanded: "false"}, class: "btn btn-sm dropdown-toggle" do
        Icon(icon: "sort-down")
        whitespace
        span { t "components.sort_menu.sort-by" }
      end
      ul class: "dropdown-menu" do
        item "sort-alpha-down", "name", "asc" # i18n-tasks-use t('components.sort_menu.name')
        item "sort-numeric-down-alt", "recent", "desc" # i18n-tasks-use t('components.sort_menu.recent')
        item "sort-numeric-down-alt", "updated", "desc" # i18n-tasks-use t('components.sort_menu.updated')
      end
    end
  end

  def ordering_by?(order)
    session["order"] == order.to_s
  end

  def ordered_url(order, direction)
    url_for({order: order, direction: direction}.merge(@filter&.to_params))
  end

  def item(icon, key, direction)
    DropdownItem icon: icon, label: t("components.sort_menu.%{key}" % {key: key}), path: ordered_url(key, direction), active: ordering_by?(key)
  end
end
