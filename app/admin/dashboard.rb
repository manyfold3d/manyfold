# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    columns do
      column do
        panel "Recent Models" do
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
      column do
        panel "Task Queue" do
          h2 do
            "#{Delayed::Job.count} jobs in queue"
          end
          table do
            tbody do
              Delayed::Job.order(locked_at: :desc).limit(20).map do |job|
                tr do
                  td { link_to(job.id, admin_task_path(job)) }
                  td { job.locked_at ? "running" : "queued" }
                  td { job.last_error ? "error" : "" }
                end
              end
            end
          end
        end
      end
    end
  end
end
