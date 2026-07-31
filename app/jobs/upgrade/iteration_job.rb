class Upgrade::IterationJob < ApplicationJob
  include JobIteration::Iteration

  unique :until_executed

  # Because we're making these unique until executed, they can't requeue themselves upon interruption
  # while they're locked. So, we explicitly unlock the job on shutdown.
  on_shutdown -> do
    Amiko.logger.debug "Unlocking job before requeuing"
    self.class.unlock!
  end
end
