# frozen_string_literal: true

class Views::PrintHosts::Edit < Views::PrintHosts::Form
  def view_template
    PageTitle title: t("views.print_hosts.edit.title"), breadcrumbs: {
      t("views.print_hosts.index.title") => print_hosts_path,
      @print_host.name => print_host_path(@print_host)
    }
    super
  end
end
