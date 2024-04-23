module ProblemsHelper
  def problem_severity(problem)
    current_user.problem_severity(problem.category) || :silent
  end

  def max_problem_severity(problems = Problem.all)
    severities = problems.select(:category).distinct.map { |p| problem_severity(p) }
    severities.max_by { |p| Problem::SEVERITIES.find_index(p) }
  end

  def problem_icon(problems = Problem.all)
    return "" if problems.empty?
    severity = max_problem_severity(problems)
    content_tag(:span, icon("exclamation-triangle-fill", Problem.model_name.human(count: 100)), class: "text-#{severity} align-middle")
  end
end
