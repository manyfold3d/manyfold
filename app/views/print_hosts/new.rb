# frozen_string_literal: true

class Views::PrintHosts::New < Views::PrintHosts::Form
  def view_template
    h3 { t("views.print_hosts.new.title") }
    super
  end
end
