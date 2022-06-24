# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    columns do
      column do
        panel "Recent Models" do
          ul do
            Model.all.order(:created_at).limit(20).map do |model|
              li link_to(model.name, admin_model_path(model))
            end
          end
        end
      end
      column do
        panel "Task Queue" do
          ul do
            Delayed::Job.all.order(:created_at).limit(20).map do |job|
              li link_to(job.id, admin_task_path(job))
            end
          end
        end
      end
    end
  end
end
