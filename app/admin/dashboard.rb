# frozen_string_literal: true

ActiveAdmin.register_page I18n.t("active_admin.dashboard") do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }
end
