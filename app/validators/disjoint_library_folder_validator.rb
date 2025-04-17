class DisjointLibraryFolderValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil?
    value.chomp!(File::SEPARATOR)
    record.errors.add attribute, :cannot_contain if library_paths.any? { |it| it.starts_with?(value + File::SEPARATOR) }
    record.errors.add attribute, :cannot_be_contained if library_paths.any? { |it| value.starts_with?(it + File::SEPARATOR) }
  end

  private

  def library_paths
    Library.pluck(:path) # rubocop:disable Pundit/UsePolicyScope
  end
end
