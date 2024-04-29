module ProblemsHelper
  def problem_severity(problem)
    current_user.problem_severity(problem.category) || :silent
  end

  def max_problem_severity(problems = Problem.all)
    return nil if problems.empty?
    severities = problems.select(:category).distinct.map { |p| problem_severity(p) }
    severities.max_by { |p| Problem::SEVERITIES.find_index(p) }
  end

  def problem_icon(severity)
    i = case severity
    when :info
      "info-circle-fill"
    when :warning
      "exclamation-triangle-fill"
    when :danger
      "x-octagon-fill"
    end
  end

  def problem_icon_tag(problems = Problem.all)
    severity = max_problem_severity(problems)
    ico = problem_icon(severity)
    content_tag(:span, icon(ico, t("problems.severities.#{severity}")), class: "text-#{severity} align-middle") if ico
  end
end
