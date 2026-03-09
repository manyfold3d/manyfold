# frozen_string_literal: true

class Upgrade::CreateSpecialListsJob < Upgrade::IterationJob
  def build_enumerator(cursor:)
    enumerator_builder.active_record_on_records(User.all, cursor: cursor)
  end

  def each_iteration(user)
    user.send :create_special_lists
  end
end
