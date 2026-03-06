# frozen_string_literal: true

class Upgrade::CreateLikedListsJob < Upgrade::IterationJob
  def build_enumerator(cursor:)
    enumerator_builder.active_record_on_records(User.all, cursor: cursor)
  end

  def each_iteration(user)
    # i18n-tasks-use t('lists.special.liked')
    List.create(name: "lists.special.liked", special: :liked, owner: user) if user.lists.find_by(special: :liked).nil?
  end
end
