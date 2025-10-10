# frozen_string_literal: true

# Originally done in db/data/20230617222353_generate_slugs.rb
class Upgrade::GenerateSlugsJob < ApplicationJob
  include JobIteration::Iteration

  unique :until_executed

  def build_enumerator(model, cursor:)
    enumerator_builder.active_record_on_records(model.unscoped.where(slug: nil), cursor: cursor)
  end

  def each_iteration(record, _model)
    record.send(:slugify_name)
    record.save!(validate: false)
  end
end
