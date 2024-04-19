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
    pn = Pathname.new(dest_folder_name)

    flags = Archive::EXTRACT_PERM
    reader = Archive::Reader.open_filename(datafile.path)
    Dir.mkdir(dest_folder_name)
    Dir.chdir(dest_folder_name) do
      reader.each_entry do |entry|
        reader.extract(entry, flags.to_i)
      end
    end

    # Checks the directory just created and if it contains only one directory,
    # moves the contents of that directory up a level, then deletes the empty directory.
    if pn.children.length == 1 && pn.children[0].directory?
      dup_dir = Pathname.new(pn.children[0])

      dup_dir.children.each do |child|
        fixed_path = Pathname.new(pn.to_s + "/" + child.basename.to_s)
        File.rename(child.to_s, fixed_path.to_s)
      end

      Dir.delete(dup_dir.to_s)
    end
  ensure
    reader&.close
  end
end
