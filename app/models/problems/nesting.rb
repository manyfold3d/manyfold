# frozen_string_literal: true

module Problems
  class Nesting < Problems::Base
    Problems::Registry.register(:nesting, self, "Model")

    class << self
      def detect(model)
        Problem.create_or_clear(model, :nesting, model.contains_other_models?)
      end
    end

    def resolve!(problem, action:)
      case action
      when :merge
        problem.update!(state: :resolving, in_progress: true)
        problem.problematic.merge!(problem.problematic.contained_models)
        problem.destroy!
        {removed: true}
      when :ignore
        problem.update!(ignored: true)
        {ignored: true}
      else
        raise ArgumentError, "Unsupported action for Nesting: #{action.inspect}"
      end
    end
  end
end
