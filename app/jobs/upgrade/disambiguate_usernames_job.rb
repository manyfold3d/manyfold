# frozen_string_literal: true

class Upgrade::DisambiguateUsernamesJob < ApplicationJob
  def perform
    suffix = 0
    FederailsCommon::FEDIVERSE_USERNAMES.each_pair do |model_name, attr|
      model = model_name.to_s.classify.constantize
      model.unscoped.find_each do |it|
        it.validate
        if it.errors.of_kind?(attr, :taken)
          suffix += 1
          new_value = "#{it.send(attr)}#{suffix}"
          it.update_attribute attr, new_value # rubocop:disable Rails/SkipsModelValidations
        end
      end
    end
  end
end
