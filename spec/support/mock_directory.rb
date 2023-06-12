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
      yield temp_path
    end
  end
end
