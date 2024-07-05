class AddS3FieldsToLibrary < ActiveRecord::Migration[7.1]
  def change
    add_column :libraries, :s3_endpoint, :string, default: nil
    add_column :libraries, :s3_region, :string, default: nil
    add_column :libraries, :s3_bucket, :string, default: nil
    add_column :libraries, :s3_access_key_id, :string, default: nil
    add_column :libraries, :s3_secret_access_key, :string, default: nil
  end
end
