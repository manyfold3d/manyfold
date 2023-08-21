class Delayed::Backend::ActiveRecord::Job
  def self.ransackable_attributes(auth_object = nil)
    ["attempts", "created_at", "failed_at", "handler", "id", "last_error", "locked_at", "locked_by", "priority", "queue", "run_at", "updated_at"]
  end
end
