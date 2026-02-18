FactoryBot.define do
  factory :model_file do
    model
    filename { Faker::File.file_name(ext: "stl") }
    attachment { filename ? Rack::Test::UploadedFile.new(StringIO.new, original_filename: filename) : nil }

    after :create do |file, context|
      type = Mime::EXTENSION_LOOKUP[File.extname(file.filename).tr(".", "")].to_s
      file.attachment_attacher.add_metadata("mime_type" => type)
      file.save!
    end
  end
end
