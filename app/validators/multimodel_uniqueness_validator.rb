class MultimodelUniquenessValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    (options[:check] || {}).each_pair do |model_name, attr|
      # Get class constant
      model = model_name.to_s.classify.constantize
      # Work out field to query
      query = (options[:case_sensitive] == false) ?
        model.arel_table[attr].lower.eq(value.downcase) :
        model.arel_table[attr].eq(value)
      # Run the check
      record.errors.add(attribute, :taken) if model.unscoped.where(query).count > 0 # rubocop:disable Pundit/AvoidUnscoped
    end
  end
end
