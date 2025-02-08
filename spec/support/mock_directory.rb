module MockDirectory
  def self.create(file_list)
    Dir.mktmpdir do |temp_path|
      # Create file stubs
      file_list.each do |f|
        begin
          FileUtils.mkdir_p(File.join(temp_path, File.dirname(f)))
        rescue Errno::EEXIST
          nil
        end
        FileUtils.touch(File.join(temp_path, f))
      end
      # Create read-only directory
      FileUtils.makedirs(File.join(temp_path, 'readonly'), mode: 0500)
      yield temp_path
    end
  end
end
