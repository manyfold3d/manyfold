FactoryBot.define do
  factory :library do
    path {
      dir = Dir.mktmpdir(Faker::File.file_name, "/tmp")
      at_exit { FileUtils.remove_entry(dir) }
      dir
    }
  end
end
