class MultimodelUniquenessValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless value
    checkvalue = (options[:punctuation_sensitive] == false) ? value.gsub(/[^[:alnum:]]/, "") : value
    (options[:check] || {}).each_pair do |model_name, attr|
      # Get class constant
      model = model_name.to_s.classify.constantize
      # Work out field to query
      query = if options[:case_sensitive] == false
        model.arel_table[attr].lower.eq(checkvalue.downcase)
      else
        DatabaseDetector.is_mysql? ? model.arel_table[attr].smatches(checkvalue) : model.arel_table[attr].eq(checkvalue)
      end
      query = query.and(model.arel_table[:id].not_eq(record.id)) if record.instance_of?(model)
      # Run the check
      record.errors.add(attribute, :taken) if model.unscoped.where(query).exists? # rubocop:disable Pundit/AvoidUnscoped
    end
  end
end
