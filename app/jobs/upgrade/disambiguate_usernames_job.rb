# frozen_string_literal: true

class Upgrade::DisambiguateUsernamesJob < ApplicationJob
  queue_as :low
  unique :until_executed

  def perform
    duplicates = duplicated_usernames
    return if duplicates.empty?
    suffix = 0
    FederailsCommon::FEDIVERSE_USERNAMES.each_pair do |model_name, attr|
      finder_scope(model_name).where(attr => duplicates).find_each do |it|
        it.validate
        if it.errors.of_kind?(attr, :taken)
          suffix += 1
          new_value = "#{it.send(attr)}#{suffix}"
          it.update_attribute attr, new_value # rubocop:disable Rails/SkipsModelValidations
        end
      end
    end
  end

  private

  def duplicated_usernames
    FederailsCommon::FEDIVERSE_USERNAMES
      .map { |model_name, attr| finder_scope(model_name).pluck(attr) }
      .flatten.tally
      .select { |k, v| k if v > 1 }
      .keys
  end

  def finder_scope(model_name)
    model_name.to_s.classify.constantize.unscoped
  end
end
