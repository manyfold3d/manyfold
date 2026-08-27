# frozen_string_literal: true

module Problems
  class Inefficient < Problems::Base
    Problems::Registry.register(:inefficient, self, "ModelFile")

    class << self
      def detect(file, note: nil)
        should_exist = note.present?
        opts = note.present? ? {note: note} : {}
        Problem.create_or_clear(file, :inefficient, should_exist, opts)
      end
    end

    def resolve!(problem, action:)
      case action
      when :convert
        problem.update!(state: :resolving, in_progress: true)
        file = problem.problematic
        # Unique FileConversionJob must not lock inside resolve_batch's write txn.
        ActiveRecord.after_all_transactions_commit do
          file.convert_later :threemf
        end
        {in_progress: true}
      when :ignore
        problem.update!(ignored: true)
        {ignored: true}
      else
        raise ArgumentError, "Unsupported action for Inefficient: #{action.inspect}"
      end
    end
  end
end
