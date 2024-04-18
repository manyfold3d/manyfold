# frozen_string_literal: true

ActiveAdmin.register_page I18n.t("active_admin.dashboard") do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    columns do
      column do
        panel I18n.t("active_admin.recent_models") do
          table do
            tbody do
              Model.recent.limit(20).map do |model|
                tr do
                  td { link_to(model.name, admin_model_path(model)) }
                  td { "#{time_ago_in_words(model.created_at)} ago" }
                end
              end
            end
          end
        end
      end
    end
  end
end
