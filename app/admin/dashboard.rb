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
      column do
        panel I18n.t("active_admin.task_queue") do
          h2 do
            I18n.t("active_admin.queue_size", count: Delayed::Job.count)
          end
          table do
            tbody do
              Delayed::Job.order(locked_at: :desc).limit(20).map do |job|
                tr do
                  td { link_to(job.id, admin_delayed_backend_active_record_job_path(job)) }
                  td { job.locked_at ? I18n.t("active_admin.jobs.state.running") : I18n.t("active_admin.jobs.state.queued") }
                  td { job.last_error ? I18n.t("active_admin.jobs.state.error") : "" }
                end
              end
            end
          end
        end
      end
    end
  end
end
