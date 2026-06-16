# frozen_string_literal: true

class Views::PrintHosts::New < Views::PrintHosts::Form
  def view_template
    PageTitle title: t("views.print_hosts.new.title"), breadcrumbs: {
      t("views.print_hosts.index.title") => print_hosts_path
    }
    super
  end
end
