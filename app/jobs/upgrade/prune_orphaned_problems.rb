# frozen_string_literal: true

class Upgrade::PruneOrphanedProblems < ApplicationJob
  include JobIteration::Iteration

  unique :until_executed

  def build_enumerator(cursor:)
    enumerator_builder.active_record_on_records(Problem.all, cursor: cursor)
  end

  def each_iteration(problem)
    problem.destroy if problem.problematic.nil?
  end
end
