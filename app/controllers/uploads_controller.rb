class UploadsController < ApplicationController
  before_action { authorize :upload }

  after_action :verify_authorized
  skip_after_action :verify_policy_scoped, only: :index

  def index
  end

  def create
    library = Library.find(params[:post][:library_pick])
    save_files(params[:upload], File.join(library.path, ""))

    if params[:post][:scan_after_upload] == "1"
      Scan::DetectFilesystemChangesJob.perform_later(library.id)
    end
    redirect_to libraries_path, notice: t(".success")
  end

  private

  def save_files(upload, library_path)
    upload["datafiles"].select { |datafile| datafile != "" }.each { |datafile|
      file_name_with_zip = datafile.original_filename
      file_name = File.basename(file_name_with_zip, File.extname(file_name_with_zip))
      dest_folder_name = library_path + file_name
      if !Dir.exist?(dest_folder_name)
        unzip(dest_folder_name, datafile)
      end
    }
  end

  def unzip(dest_folder_name, datafile)
    flags = Archive::EXTRACT_PERM
    reader = Archive::Reader.open_filename(datafile.path)
    Dir.mkdir(dest_folder_name)
    Dir.chdir(dest_folder_name) do
      reader.each_entry do |entry|
        # For non-directory files, strips the path and extracts to current directory
        if !entry.directory?
          pn = Pathname.new(entry.pathname)
          file_name = pn.basename
          entry.pathname=(file_name.to_s)
          reader.extract(entry, flags.to_i)
          end
      end
    end
  ensure
    reader&.close
  end
end
