require "zip"

class UploadsController < ApplicationController
  def create
    library = Library.find(params[:post][:library_pick])
    save_files(params[:upload], File.join(library.path, ""))

    if params[:post][:scan_after_upload] == "1"
      LibraryScanJob.perform_later(library)
    end
    redirect_to libraries_path
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
    Dir.mkdir(dest_folder_name)

    Zip::File.open(datafile) do |zipfile|
      zipfile.each do |f|
        f_path = File.join(dest_folder_name, f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zipfile.extract(f, f_path) unless File.exist?(f_path)
      end
    end
  end
end
