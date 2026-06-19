# frozen_string_literal: true

class Views::PrintHosts::Edit < Views::PrintHosts::Form
  def view_template
    h3 { t("views.print_hosts.edit.title") }
    super
  end
end
