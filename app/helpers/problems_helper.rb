module ProblemsHelper
  def problem_severity(problem)
    {
      missing: :danger,
      empty: :info,
      nesting: :warning,
      inefficient: :info,
      duplicate: :warning
    }[problem.category.to_sym] || :silent
  end

  def max_problem_severity
    severities = Problem.select(:category).distinct.map { |p| problem_severity(p) }
    severities.max_by { |p| Problem::SEVERITIES.find_index(p) }
  end
end
