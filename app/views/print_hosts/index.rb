# frozen_string_literal: true

module Views::PrintHosts
  class Index < Views::Base
    def initialize(print_hosts:)
      @print_hosts = print_hosts
    end

    def view_template
      h3 { t("views.print_hosts.index.title") }
      p { t("views.print_hosts.index.description") }
      table class: "table table-striped" do
        tr do
          th
          th { PrintHost.human_attribute_name :name }
          th { PrintHost.human_attribute_name :endpoint }
          th { PrintHost.human_attribute_name :protocol }
          th
        end
        @print_hosts.each do |print_host|
          tr do
            td { print_host.service.ok? ? "✅" : "❌" }
            td { print_host.name }
            td { code { print_host.endpoint } }
            td { translate("print_hosts.protocols.%{protocol}" % {protocol: print_host.protocol}) }
            td { GoButton label: t("views.print_hosts.edit.title"), icon_only: true, href: edit_print_host_path(print_host), icon: "pencil", variant: :secondary }
          end
        end
      end
      GoButton icon: "plus-circle", label: t("views.print_hosts.new.title"), href: new_print_host_path, variant: :primary
    end
  end
end
