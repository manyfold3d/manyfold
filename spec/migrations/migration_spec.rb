# Test migrations
#
# This approach runs migrations up to a specified point, loads an SQL file at that point, then runs
# the rest of the migrations. The idea is to allow snapshots of a database at any point in time and
# make sure we can migrate from it in order to catch errors due to data manipulation or code mismatches.
#
# To add a new test, just add a new SQL file in spec/fixtures/migrations, named with the appropriate Rails
# migration timestamp, with data which should be inserted into the test database at that point. The rest
# will be handled automatically, there is no need to edit this file.

RSpec.describe "Migrations" do
  Rails.root.glob("spec/fixtures/migrations/*.sql").map { |it| File.basename(it.to_s.split("/").last, ".*") }.each do |version|
    context "when migrating database version #{version} to latest", :migration do
      let(:database) { "tmp/migration-test-#{version}.db" }

      it "completes successfully" do
        migrate(to: version)
        ActiveRecord::Base.connection.execute(File.read("spec/fixtures/migrations/#{version}.sql"))
        expect { migrate(from: version) }.not_to raise_error
      end
    end
  end
end
