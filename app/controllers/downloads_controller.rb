require 'zip'
require "fileutils"

class DownloadsController < ApplicationController
    include ActionController::Live

    include ModelFilters
    before_action :get_library, only: [:write]
    before_action :get_model, only: [:write]

    def write
        @input_dir = File.join(@library.path, @model.path)
        @output_file = "tmp/#{@model.name}_#{@model.id}.zip"
        entries = Dir.entries(@input_dir) - %w[. ..]
        
        if File.exist?(@output_file)
            send_file(Rails.root.join(@output_file), :type => 'application/zip', :filename => "#{@model.name.downcase.gsub(/\s+/, '_')}.zip", :disposition => 'attachment')
        else
            ::Zip::File.open(@output_file, ::Zip::File::CREATE) do |zipfile|
                write_entries entries, '', zipfile
            end
            send_file(Rails.root.join(@output_file), :type => 'application/zip', :filename => "#{@model.name.downcase.gsub(/\s+/, '_')}.zip", :disposition => 'attachment')
        end
    end

    def get_library
        @library = Model.find(params[:id]).library
      end
    
    def get_model
        @model = Model.includes(:model_files).find(params[:id])
    end

    private

    # A helper method to make the recursion work.
    def write_entries(entries, path, zipfile)
        entries.each do |e|
            zipfile_path = path == '' ? e : File.join(path, e)
            disk_file_path = File.join(@input_dir, zipfile_path)

            if File.directory? disk_file_path
                recursively_deflate_directory(disk_file_path, zipfile, zipfile_path)
            else
                put_into_archive(disk_file_path, zipfile, zipfile_path)
            end
        end
    end

    def recursively_deflate_directory(disk_file_path, zipfile, zipfile_path)
        zipfile.mkdir zipfile_path
        subdir = Dir.entries(disk_file_path) - %w[. ..]
        write_entries subdir, zipfile_path, zipfile
    end

    def put_into_archive(disk_file_path, zipfile, zipfile_path)
        zipfile.add(zipfile_path, disk_file_path)
    end
end