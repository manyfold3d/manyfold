module ProblemsHelper
  def problem_severity(problem)
    case problem.category.to_sym
    when :missing
      "danger"
    when :nesting, :duplicate
      "warning"
    else
      "info"
    end
  end

  def max_problem_severity
    return "danger" if Problem.where(category: :missing).count > 0
    return "warning" if Problem.where(category: [:nesting, :duplicate]).count > 0
    "info"
  end
end
