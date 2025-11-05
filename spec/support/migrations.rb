# Helper methods for running migrations
# This is a little more complex than it would be using plain ActiveRecord migrations,
# because we also have DataMigrate in the mix.

RSpec.shared_context "with migration helpers" do
  let(:data_migration_context) { DataMigrate::MigrationContext.new }
  let(:migration_context) { ActiveRecord::MigrationContext.new(ActiveRecord::Migrator.migrations_paths) }

  def migrate(to: nil, from: nil)
    # Work out which migrations we're going to run
    version = to&.to_i || from&.to_i
    raise ArgumentError.new("you must specify to: or from:") if version.nil?
    all_versions = (migration_context.pending_migration_versions + data_migration_context.pending_migration_versions).sort
    before, after = all_versions.partition { |i| i <= version.to_i }
    migrations = to ? before : after
    # Run them each in turn
    ActiveRecord::Migration.suppress_messages do
      migrations.each do |migration|
        migration_context.migrate migration
      rescue ActiveRecord::UnknownMigrationVersionError
        data_migration_context.migrate migration
      end
    end
  end

  def load_sql(version)
    queries = File.read("spec/fixtures/migrations/#{version}.sql")
    queries.split(";").compact_blank.each { |it| ActiveRecord::Base.connection.execute(it) }
  end
end

# Setup for migration tests

RSpec.configure do |config|
  config.include_context "with migration helpers", :migration
  config.around(:each, :migration) do |example|
    # Setup
    FileUtils.rm(Rails.root.glob(database + "*"), force: true)
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: database)
    ActiveRecord::Base.descendants.each(&:reset_column_information)
    DataMigrate::DataMigrator.create_data_schema_table
    # Run
    example.run
    # Teardown
    ActiveRecord::Base.connection.close
    ActiveRecord::Base.establish_connection(:test)
    ActiveRecord::Base.descendants.each(&:reset_column_information)
  end
end
