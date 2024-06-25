class AddAttachmentDataToModelFiles < ActiveRecord::Migration[7.0]
  def change
    add_column :model_files, :attachment_data, :json
  end
end
