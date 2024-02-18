require 'zip'
require "fileutils"

class DownloadsController < ApplicationController
    include ActionController::Live

    include ModelFilters
    before_action :get_library, except: [:index, :bulk_edit, :bulk_update]
    before_action :get_model, except: [:bulk_edit, :bulk_update, :index]
    before_action :get_files, only: [:process_and_create_zip_file]

    def process_and_create_zip_file
        full_path = File.join(@library.path, @model.path)
        file_paths = Dir.glob(File.join(full_path, '*'))
        job = file_paths.map do |path|
            OpenStruct.new(filename: File.basename(path), path: path)
        end
        tmp_user_folder = "tmp/archive_#{current_user.id}"
        directory_length_same_as_files = Dir["#{tmp_user_folder}/*"].length == job.length
        FileUtils.mkdir_p(tmp_user_folder) unless Dir.exist?(tmp_user_folder)
        job.each do |file|
            filename = file.filename.to_s
            create_tmp_folder_and_store_files(file, tmp_user_folder, filename) unless directory_length_same_as_files
            create_zip_from_tmp_folder(tmp_user_folder, filename) unless directory_length_same_as_files
        end

        send_file(Rails.root.join("#{tmp_user_folder}.zip"), :type => 'application/zip', :filename => "Files_for_#{@model.name.downcase.gsub(/\s+/, '_')}.zip", :disposition => 'attachment')
        # TODO: Remove files at a later date
        # as zip file wont be able to downloads if uncommented
        # FileUtils.rm_rf([tmp_user_folder, "#{tmp_user_folder}.zip"])
    end

    def create_tmp_folder_and_store_files(document, tmp_user_folder, filename)
        source_path = document.path # Assuming this is the full path to the source file
        dest_path = File.join(tmp_user_folder, filename)
    
        FileUtils.copy_file(source_path, dest_path)
    end
    

    def create_zip_from_tmp_folder(tmp_user_folder, filename)
        Zip::File.open("#{tmp_user_folder}.zip", Zip::File::CREATE) do |zf|
            zf.add(filename, "#{tmp_user_folder}/#{filename}")
        end
    end

    def get_library
        @library = Model.find(params[:id]).library
      end
    
    def get_model
        @model = Model.includes(:model_files).find(params[:id])
        @title = @model.name
    end

    def get_files
        @files = @model.model_files
    end
end