class ReadWriteValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil?
    record.errors.add attribute, :not_a_directory unless FileTest.directory?(value)
    record.errors.add attribute, :non_readable unless FileTest.readable?(value)
    record.errors.add attribute, :non_writable unless FileTest.writable?(value)
    # Make sure subfolder permissions are OK as well
    if File.exist?(value) && record.errors.empty?
      # Use Dir.glob because it leaves out hidden files
      Dir.glob(File.join(value, "*")).each do |path|
        if FileTest.directory?(path)
          record.errors.add attribute, :non_readable_subfolder unless FileTest.readable?(path)
          record.errors.add attribute, :non_writable_subfolder unless FileTest.writable?(path)
        end
      end
    end
  end
end
