ActiveAdmin.register Delayed::Job do
  actions :all, except: [:new]

  collection_action :run_all, method: :post do
    successes, failures = Delayed::Worker.new.work_off
    if failures > 0
      flash[:alert] = "#{failures} failed Tasks when running them."
    end
    if successes > 0
      flash[:notice] = "#{successes} Tasks run successfully"
    end
    if failures == 0 && successes == 0
      flash[:notice] = "Yawn... no Tasks run"
    end
    redirect_to admin_delayed_backend_active_record_jobs_url
    I18n.locale = :en # Running tasks can mess up the locale.
  end

  if Rails.env.development?
    collection_action :delete_all, method: :post do
      n = Delayed::Job.delete_all
      redirect_to admin_delayed_backend_active_record_jobs_url, notice: "#{n} tasks deleted."
    end
  end

  collection_action :mark_all_for_re_run, method: :post do
    n = Delayed::Job.update_all("run_at = created_at")
    redirect_to admin_delayed_backend_active_record_jobs_url, notice: "Marked all tasks (#{n}) for re-running."
  end

  member_action :run, method: :post do
    task = Delayed::Job.find(params[:id])
    begin
      task.invoke_job
      task.destroy
      redirect_to admin_delayed_backend_active_record_jobs_url, notice: "1 Task run, apparently successfully, but who knows!"
    rescue => e
      redirect_to admin_delayed_backend_active_record_jobs_url, alert: "Failed to run a Task: #{e}"
    end
    I18n.locale = :en # Running Tasks can mess up the locale.
  end

  action_item :run do
    links = [
      link_to("Run All Tasks", run_all_admin_delayed_backend_active_record_jobs_url, method: :post),
      link_to("Mark all for re-run", mark_all_for_re_run_admin_delayed_backend_active_record_jobs_url, method: :post)
    ]
    links.push link_to("Delete All Tasks", delete_all_admin_delayed_backend_active_record_jobs_url, method: :post) if Rails.env.development?
    safe_join links, " "
  end

  index do
    selectable_column
    id_column
    column "P", :priority
    column "A", :attempts
    column("Error", :last_error, sortable: :last_error) { |post| post.last_error.present? ? post.last_error.split('\n').first : "" }
    column(:created_at, sortable: :created_at) { |job| job.created_at.iso8601.tr("T", " ") }
    column(:run_at, sortable: :run_at) { |post| post.run_at.present? ? post.run_at.iso8601.tr("T", " ") : nil }
    column :queue
    column("Running", sortable: :locked_at) { |dj| dj.locked_at.present? ? "#{(Time.zone.now - dj.locked_at).round(1)}s by #{dj.locked_by}" : "" }
    actions
  end

  show title: ->(dj) { "Task #{dj.id}" } do |task|
    panel "Task" do
      attributes_table_for task do
        row :id
        row :priority
        row :attempts
        row :queue
        row :run_at
        row :locked_at
        row :failed_at
        row :locked_by
        row :created_at
        row :updated_at
      end
    end

    panel "Handler" do
      pre task.handler
    rescue => e
      div "Couldn't render handler: #{e.message}"
    end

    panel "Last error" do
      pre task.last_error
    rescue => e
      div "Couldn't render last error: #{e.message}"
    end
  end

  form do |f|
    f.inputs("Task") do
      f.input :id, input_html: {readonly: true}
      f.input :priority
      f.input :attempts
      f.input :queue
      f.input :created_at, input_html: {readonly: true}, as: :string
      f.input :updated_at, input_html: {readonly: true}, as: :string
      f.input :run_at, input_html: {readonly: true}, as: :string
      f.input :locked_at, input_html: {readonly: true}, as: :string
      f.input :failed_at, input_html: {readonly: true}, as: :string
      f.input :locked_by, input_html: {readonly: true}
    end

    f.buttons
  end

  controller do
    def update
      @task = Delayed::Job.find(params[:id])
      @task.assign_attributes(params[:task], without_protection: true)
      if @task.save
        redirect_to admin_delayed_backend_active_record_jobs_url, notice: "Task #{@task} saved successfully"
      else
        render :edit
      end
      I18n.locale = :en # Running Tasks can mess up the locale.
    end
  end
end
