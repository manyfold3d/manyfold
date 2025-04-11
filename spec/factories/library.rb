FactoryBot.define do
  factory :library do
    sequence(:name) { |n| "Library #{n}" }
    sequence(:public_id) { |n| "library_#{n}" }
    path { # rubocop:disable RSpec/MissingExampleGroupArgument, RSpec/EmptyExampleGroup
      dir = Dir.mktmpdir(Faker::File.file_name, "/tmp")
      at_exit { FileUtils.remove_entry(dir) }
      dir
    }
  end
end
