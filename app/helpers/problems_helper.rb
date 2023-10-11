module ProblemsHelper
  def problem_severity(problem)
    {
      missing: "danger",
      empty: "info",
      nesting: "warning",
      inefficient: "info",
      duplicate: "warning"
    }[problem.category.to_sym] || "info"
  end

  def max_problem_severity
    return "danger" if Problem.where(category: :missing).count > 0
    return "warning" if Problem.where(category: [:nesting, :duplicate]).count > 0
    "info"
  end
end
