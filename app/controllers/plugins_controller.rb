class PluginsController < ApplicationController
  layout "settings"

  def index
    skip_policy_scope
    @plugins = PLUGINS.values
    respond_to do |format|
      format.html { render Views::Plugins::Index.new(plugins: @plugins) }
    end
  end

  def create
    # No specific authorisation needed other than "user is admin" which is already checked by this point
    skip_authorization
    # Process the uploaded file
    extract_plugin(params.expect(:plugin_file))
    # Back we go
    redirect_to settings_plugins_path
  end

  private

  def extract_plugin(archive)
    # Extract the file synchronously rather than in a background job. This is intentional!
    plugin_path = Rails.root.join("plugins", File.basename(archive.original_filename, ".*"))
    begin
      plugin_path.mkdir
    rescue Errno::EEXIST
      Rails.logger.warn("Plugin path #{plugin_path} exists, files will be overwritten")
    end
    flags = [
      Archive::EXTRACT_TIME,
      Archive::EXTRACT_SECURE_NODOTDOT
    ].reduce(:|).to_i
    strip = count_common_path_components(archive)
    Archive::Reader.open_filename(archive.tempfile.path, strip_components: strip) do |reader|
      reader.each_entry do |entry|
        reader.extract(entry, flags, destination: plugin_path.to_s)
      end
    end
    # Set the flag that a restart is now needed
    Rails.cache.write("restart_required", true)
  end

  def count_common_path_components(archive)
    # Generate full list of directories in the archive
    paths = []
    files_in_root = false
    Archive::Reader.open_filename(archive.path) do |reader|
      reader.each_entry do |entry|
        paths << entry.pathname if entry.directory?
        files_in_root = true if entry.file? && entry.pathname.exclude?(File::SEPARATOR)
      end
    end
    return 0 if files_in_root
    paths = paths.map { |path| path.split(File::SEPARATOR) }
    # Count the common elements in the paths
    count_common_elements(paths)
  end

  def count_common_elements(arrays)
    return 0 if arrays.empty?
    first = arrays.shift
    zip = first.zip(*arrays)
    zip.count { it.uniq.count == 1 }
  end
end
